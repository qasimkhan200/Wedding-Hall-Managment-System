import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../utils/map_performance_monitor.dart';

/// KPK-optimized Map Service with caching and performance optimizations
class KpkOptimizedMapService {
  // Multiple CDN servers for better performance in Pakistan
  static const List<String> _osrmServers = [
    'https://router.project-osrm.org/route/v1/driving',
    'https://routing.openstreetmap.de/routed-car/route/v1/driving',
  ];

  // KPK-specific bounds for optimized searches
  static const double kpkMinLat = 31.0;
  static const double kpkMaxLat = 37.0;
  static const double kpkMinLng = 69.0;
  static const double kpkMaxLng = 75.0;

  // Major cities in KPK for preloading
  static const Map<String, LatLng> kpkCities = {
    'Peshawar': LatLng(34.0151, 71.5249),
    'Islamabad': LatLng(33.6844, 73.0479),
    'Rawalpindi': LatLng(33.5651, 73.0169),
    'Mardan': LatLng(34.1987, 72.0407),
    'Abbottabad': LatLng(34.1463, 73.2211),
    'Kohat': LatLng(33.5919, 71.4425),
    'Bannu': LatLng(32.9889, 70.6011),
    'Swat': LatLng(35.2227, 72.4258),
  };

  static const String _userAgent = 'com.orginize.app.kpk';
  static const Duration _timeout =
      Duration(seconds: 8); // Reduced for mobile networks

  // Cache keys
  static const String _routeCacheKey = 'kpk_route_cache';
  static const String _searchCacheKey = 'kpk_search_cache';
  static const String _frequentLocationsKey = 'frequent_locations';

  // In-memory caches
  static final Map<String, RouteInfo> _routeCache = {};
  static final Map<String, List<PlaceSearchResult>> _searchCache = {};
  static int _currentServerIndex = 0;

  /// Get route with KPK optimizations and caching
  static Future<RouteInfo?> getRouteWithInfo(
    LatLng start,
    LatLng end, {
    String profile = 'driving',
  }) async {
    final timer = MapPerformanceMonitor.startTimer('route_calculation');

    try {
      // Check cache first
      final cacheKey = _getRouteKey(start, end);
      if (_routeCache.containsKey(cacheKey)) {
        developer.log('Route cache hit: $cacheKey');
        MapPerformanceMonitor.recordCacheHit('route');
        timer.stop();
        return _routeCache[cacheKey];
      }

      // Check persistent cache
      final cachedRoute = await _getCachedRoute(cacheKey);
      if (cachedRoute != null) {
        _routeCache[cacheKey] = cachedRoute;
        MapPerformanceMonitor.recordCacheHit('route');
        timer.stop();
        return cachedRoute;
      }

      MapPerformanceMonitor.recordCacheMiss('route');

      // Check connectivity
      final connectivity = await Connectivity().checkConnectivity();
      if (connectivity == ConnectivityResult.none) {
        developer.log('No internet connection for routing');
        timer.stop();
        return null;
      }

      // Try multiple servers for better reliability
      for (int i = 0; i < _osrmServers.length; i++) {
        final serverIndex = (_currentServerIndex + i) % _osrmServers.length;
        final route = await _fetchRouteFromServer(start, end, serverIndex);

        if (route != null) {
          _currentServerIndex = serverIndex; // Use this server next time
          _routeCache[cacheKey] = route;
          await _saveRouteToCache(cacheKey, route);
          await _updateFrequentLocations(start, end);

          timer.stop();
          MapPerformanceMonitor.recordRoute(
              timer.elapsedMilliseconds, route.distance / 1000);

          return route;
        }
      }

      timer.stop();
      return null;
    } catch (e) {
      timer.stop();
      rethrow;
    }
  }

  /// Search places with KPK-specific optimizations
  static Future<List<PlaceSearchResult>> searchPlaces(
    String query, {
    int limit = 5,
    LatLng? nearLocation,
  }) async {
    if (query.isEmpty) return [];

    final timer = MapPerformanceMonitor.startTimer('search');

    try {
      // Check cache first
      final cacheKey = query.toLowerCase().trim();
      if (_searchCache.containsKey(cacheKey)) {
        developer.log('Search cache hit: $cacheKey');
        MapPerformanceMonitor.recordCacheHit('search');
        timer.stop();
        MapPerformanceMonitor.recordSearch(
            timer.elapsedMilliseconds, _searchCache[cacheKey]!.length);
        return _searchCache[cacheKey]!;
      }

      // Check persistent cache
      final cachedResults = await _getCachedSearch(cacheKey);
      if (cachedResults.isNotEmpty) {
        _searchCache[cacheKey] = cachedResults;
        MapPerformanceMonitor.recordCacheHit('search');
        timer.stop();
        MapPerformanceMonitor.recordSearch(
            timer.elapsedMilliseconds, cachedResults.length);
        return cachedResults;
      }

      MapPerformanceMonitor.recordCacheMiss('search');

      // Optimize query for KPK
      String optimizedQuery = _optimizeQueryForKpk(query);

      // Build search parameters optimized for KPK
      final params = {
        'q': optimizedQuery,
        'format': 'json',
        'limit': limit.toString(),
        'addressdetails': '1',
        'countrycodes': 'pk', // Pakistan only
        'bounded': '1',
        'viewbox': '$kpkMinLng,$kpkMinLat,$kpkMaxLng,$kpkMaxLat', // KPK bounds
      };

      // Add proximity if location provided
      if (nearLocation != null) {
        params['lat'] = nearLocation.latitude.toString();
        params['lon'] = nearLocation.longitude.toString();
      }

      try {
        final uri = Uri.parse(
            'https://nominatim.openstreetmap.org/search?${Uri(queryParameters: params).query}');

        final response = await http
            .get(uri, headers: {'User-Agent': _userAgent}).timeout(_timeout);

        if (response.statusCode == 200) {
          final List data = json.decode(response.body);
          final results = data
              .map((item) => PlaceSearchResult(
                    displayName: item['display_name'],
                    latitude: double.parse(item['lat']),
                    longitude: double.parse(item['lon']),
                    placeId: item['place_id']?.toString(),
                    address: _parseAddress(item['address']),
                  ))
              .where((result) => _isInKpk(result.position))
              .toList();

          // Cache results
          _searchCache[cacheKey] = results;
          await _saveSearchToCache(cacheKey, results);

          timer.stop();
          MapPerformanceMonitor.recordSearch(
              timer.elapsedMilliseconds, results.length);

          return results;
        }
      } catch (e) {
        developer.log('Search error: $e');
      }

      timer.stop();
      return [];
    } catch (e) {
      timer.stop();
      rethrow;
    }
  }

  /// Preload tiles and routes for KPK cities
  static Future<void> preloadKpkData() async {
    developer.log('Preloading KPK map data...');

    // Preload routes between major cities
    final cities = kpkCities.values.toList();
    for (int i = 0; i < cities.length; i++) {
      for (int j = i + 1; j < cities.length; j++) {
        // Don't await - run in background
        getRouteWithInfo(cities[i], cities[j]).catchError((e) {
          developer.log('Preload route error: $e');
          return null;
        });
      }
    }
  }

  /// Get frequent locations for the user
  static Future<List<LatLng>> getFrequentLocations() async {
    final prefs = await SharedPreferences.getInstance();
    final locations = prefs.getStringList(_frequentLocationsKey) ?? [];

    return locations.map((loc) {
      final parts = loc.split(',');
      return LatLng(double.parse(parts[0]), double.parse(parts[1]));
    }).toList();
  }

  /// Clear all caches
  static Future<void> clearCaches() async {
    _routeCache.clear();
    _searchCache.clear();

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_routeCacheKey);
    await prefs.remove(_searchCacheKey);

    developer.log('All caches cleared');
  }

  /// Calculate distance between two points in kilometers
  static double calculateDistance(LatLng point1, LatLng point2) {
    const double earthRadius = 6371.0;
    final double dLat = (point2.latitude - point1.latitude) * (pi / 180);
    final double dLon = (point2.longitude - point1.longitude) * (pi / 180);

    final double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(point1.latitude * (pi / 180)) *
            cos(point2.latitude * (pi / 180)) *
            sin(dLon / 2) *
            sin(dLon / 2);

    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  // Private helper methods
  static Future<RouteInfo?> _fetchRouteFromServer(
    LatLng start,
    LatLng end,
    int serverIndex,
  ) async {
    try {
      final url = Uri.parse(
        '${_osrmServers[serverIndex]}/${start.longitude},${start.latitude};'
        '${end.longitude},${end.latitude}'
        '?overview=simplified&geometries=polyline&steps=false',
      );

      developer.log('Fetching route from server $serverIndex: $url');

      final response = await http
          .get(url, headers: {'User-Agent': _userAgent}).timeout(_timeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['code'] != 'Ok') {
          developer
              .log('OSRM Error from server $serverIndex: ${data['message']}');
          return null;
        }

        if (data['routes'] != null && (data['routes'] as List).isNotEmpty) {
          final route = data['routes'][0];
          final points = _decodePolyline(route['geometry']);

          return RouteInfo(
            points: points,
            distance: (route['distance'] as num).toDouble(),
            duration: (route['duration'] as num).toDouble(),
          );
        }
      }
    } catch (e) {
      developer.log('Server $serverIndex error: $e');
    }
    return null;
  }

  static String _optimizeQueryForKpk(String query) {
    final lowerQuery = query.toLowerCase();

    // Add KPK context if not present
    if (!lowerQuery.contains('kpk') &&
        !lowerQuery.contains('khyber') &&
        !lowerQuery.contains('pakistan') &&
        !lowerQuery.contains('peshawar') &&
        !kpkCities.keys
            .any((city) => lowerQuery.contains(city.toLowerCase()))) {
      return '$query, KPK, Pakistan';
    }

    return query;
  }

  static bool _isInKpk(LatLng position) {
    return position.latitude >= kpkMinLat &&
        position.latitude <= kpkMaxLat &&
        position.longitude >= kpkMinLng &&
        position.longitude <= kpkMaxLng;
  }

  static String _getRouteKey(LatLng start, LatLng end) {
    return '${start.latitude.toStringAsFixed(3)},${start.longitude.toStringAsFixed(3)}-'
        '${end.latitude.toStringAsFixed(3)},${end.longitude.toStringAsFixed(3)}';
  }

  static Future<RouteInfo?> _getCachedRoute(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheData = prefs.getString('$_routeCacheKey:$key');
      if (cacheData != null) {
        final data = json.decode(cacheData);
        final timestamp = data['timestamp'] as int;

        // Cache valid for 24 hours
        if (DateTime.now().millisecondsSinceEpoch - timestamp <
            24 * 60 * 60 * 1000) {
          return RouteInfo.fromJson(data['route']);
        }
      }
    } catch (e) {
      developer.log('Cache read error: $e');
    }
    return null;
  }

  static Future<void> _saveRouteToCache(String key, RouteInfo route) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheData = {
        'route': route.toJson(),
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };
      await prefs.setString('$_routeCacheKey:$key', json.encode(cacheData));
    } catch (e) {
      developer.log('Cache save error: $e');
    }
  }

  static Future<List<PlaceSearchResult>> _getCachedSearch(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheData = prefs.getString('$_searchCacheKey:$key');
      if (cacheData != null) {
        final data = json.decode(cacheData);
        final timestamp = data['timestamp'] as int;

        // Cache valid for 7 days
        if (DateTime.now().millisecondsSinceEpoch - timestamp <
            7 * 24 * 60 * 60 * 1000) {
          return (data['results'] as List)
              .map((item) => PlaceSearchResult.fromJson(item))
              .toList();
        }
      }
    } catch (e) {
      developer.log('Search cache read error: $e');
    }
    return [];
  }

  static Future<void> _saveSearchToCache(
      String key, List<PlaceSearchResult> results) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheData = {
        'results': results.map((r) => r.toJson()).toList(),
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };
      await prefs.setString('$_searchCacheKey:$key', json.encode(cacheData));
    } catch (e) {
      developer.log('Search cache save error: $e');
    }
  }

  static Future<void> _updateFrequentLocations(LatLng start, LatLng end) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final locations = prefs.getStringList(_frequentLocationsKey) ?? [];

      final startStr = '${start.latitude},${start.longitude}';
      final endStr = '${end.latitude},${end.longitude}';

      // Add to frequent locations (keep last 20)
      locations.remove(startStr);
      locations.remove(endStr);
      locations.insert(0, startStr);
      locations.insert(0, endStr);

      if (locations.length > 20) {
        locations.removeRange(20, locations.length);
      }

      await prefs.setStringList(_frequentLocationsKey, locations);
    } catch (e) {
      developer.log('Frequent locations update error: $e');
    }
  }

  static List<LatLng> _decodePolyline(String encoded) {
    final List<LatLng> poly = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      poly.add(LatLng((lat / 1E5).toDouble(), (lng / 1E5).toDouble()));
    }
    return poly;
  }

  static Map<String, String> _parseAddress(Map<String, dynamic>? address) {
    if (address == null) return {};
    return {
      if (address['house_number'] != null) 'house': address['house_number'],
      if (address['road'] != null) 'road': address['road'],
      if (address['suburb'] != null) 'suburb': address['suburb'],
      if (address['city'] != null ||
          address['town'] != null ||
          address['village'] != null)
        'city': address['city'] ?? address['town'] ?? address['village'],
      if (address['state'] != null) 'state': address['state'],
      if (address['postcode'] != null) 'postcode': address['postcode'],
      if (address['country'] != null) 'country': address['country'],
    };
  }
}

// Enhanced models with JSON serialization
class RouteInfo {
  final List<LatLng> points;
  final double distance;
  final double duration;

  RouteInfo(
      {required this.points, required this.distance, required this.duration});

  String get distanceKm => '${(distance / 1000).toStringAsFixed(1)} km';
  String get durationMinutes => '${(duration / 60).toStringAsFixed(0)} min';

  Map<String, dynamic> toJson() => {
        'points': points.map((p) => [p.latitude, p.longitude]).toList(),
        'distance': distance,
        'duration': duration,
      };

  factory RouteInfo.fromJson(Map<String, dynamic> json) => RouteInfo(
        points:
            (json['points'] as List).map((p) => LatLng(p[0], p[1])).toList(),
        distance: json['distance'].toDouble(),
        duration: json['duration'].toDouble(),
      );
}

class PlaceSearchResult {
  final String displayName;
  final double latitude;
  final double longitude;
  final String? placeId;
  final Map<String, String> address;

  PlaceSearchResult({
    required this.displayName,
    required this.latitude,
    required this.longitude,
    this.placeId,
    this.address = const {},
  });

  LatLng get position => LatLng(latitude, longitude);

  Map<String, dynamic> toJson() => {
        'displayName': displayName,
        'latitude': latitude,
        'longitude': longitude,
        'placeId': placeId,
        'address': address,
      };

  factory PlaceSearchResult.fromJson(Map<String, dynamic> json) =>
      PlaceSearchResult(
        displayName: json['displayName'],
        latitude: json['latitude'].toDouble(),
        longitude: json['longitude'].toDouble(),
        placeId: json['placeId'],
        address: Map<String, String>.from(json['address'] ?? {}),
      );
}
