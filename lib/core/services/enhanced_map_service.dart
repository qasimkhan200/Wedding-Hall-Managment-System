import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

/// Enhanced Map Service with routing, geocoding, and place search
class EnhancedMapService {
  // OSRM Routing Server - Using HTTPS for Android compatibility
  static const String _osrmBaseUrl =
      'https://router.project-osrm.org/route/v1/driving';

  // Nominatim Geocoding
  static const String _nominatimUrl = 'https://nominatim.openstreetmap.org';
  static const String _userAgent = 'com.orginize.app';

  // Timeout for API requests - increased for better reliability
  static const Duration _timeout = Duration(seconds: 15);

  /// Get route between two points with driving profile
  static Future<List<LatLng>> getRoute(
    LatLng start,
    LatLng end, {
    String profile = 'driving',
    bool alternatives = false,
  }) async {
    try {
      final url = Uri.parse(
        '$_osrmBaseUrl/${start.longitude},${start.latitude};'
        '${end.longitude},${end.latitude}'
        '?overview=full&geometries=polyline&alternatives=$alternatives'
        '&steps=false',
      );

      developer.log('Fetching route from: $url');

      final response = await http
          .get(url, headers: {'User-Agent': _userAgent}).timeout(_timeout);

      developer.log('OSRM Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['code'] != 'Ok') {
          developer.log('OSRM Error: ${data['message']}');
          return [];
        }

        if (data['routes'] != null && (data['routes'] as List).isNotEmpty) {
          final geometry = data['routes'][0]['geometry'] as String;
          final points = _decodePolyline(geometry);
          developer.log('Decoded ${points.length} route points');
          return points;
        }
      } else {
        developer
            .log('OSRM HTTP Error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      developer.log('OSRM Route error: $e');
    }
    return [];
  }

  /// Get route with additional info (distance, duration)
  static Future<RouteInfo?> getRouteWithInfo(
    LatLng start,
    LatLng end, {
    String profile = 'driving',
  }) async {
    try {
      final url = Uri.parse(
        '$_osrmBaseUrl/${start.longitude},${start.latitude};'
        '${end.longitude},${end.latitude}'
        '?overview=full&geometries=polyline&steps=false',
      );

      developer.log('Fetching route info from: $url');

      final response = await http
          .get(url, headers: {'User-Agent': _userAgent}).timeout(_timeout);

      developer.log('OSRM Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['code'] != 'Ok') {
          developer.log('OSRM Error: ${data['message']}');
          return null;
        }

        if (data['routes'] != null && (data['routes'] as List).isNotEmpty) {
          final route = data['routes'][0];
          final points = _decodePolyline(route['geometry']);
          developer.log('Decoded ${points.length} route points');

          return RouteInfo(
            points: points,
            distance: (route['distance'] as num).toDouble(),
            duration: (route['duration'] as num).toDouble(),
          );
        }
      } else {
        developer
            .log('OSRM HTTP Error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      developer.log('OSRM RouteInfo error: $e');
    }
    return null;
  }

  /// Search for places using Nominatim
  static Future<List<PlaceSearchResult>> searchPlaces(
    String query, {
    int limit = 5,
    String? countryCode,
  }) async {
    if (query.isEmpty) return [];

    String searchQuery = query;
    if (!query.toLowerCase().contains('peshawar') &&
        !query.toLowerCase().contains('pakistan')) {
      searchQuery = '$query, Peshawar';
    }

    final params = {
      'q': searchQuery,
      'format': 'json',
      'limit': limit.toString(),
      'addressdetails': '1',
      if (countryCode != null) 'countrycodes': countryCode,
    };

    final uri = Uri.parse(
        '$_nominatimUrl/search?${Uri(queryParameters: params).query}');
    final response = await http.get(uri, headers: {'User-Agent': _userAgent});

    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      return data
          .map((item) => PlaceSearchResult(
                displayName: item['display_name'],
                latitude: double.parse(item['lat']),
                longitude: double.parse(item['lon']),
                placeId: item['place_id']?.toString(),
                address: _parseAddress(item['address']),
              ))
          .toList();
    }
    return [];
  }

  /// Reverse geocode coordinates to address
  static Future<String?> reverseGeocode(LatLng position) async {
    final uri = Uri.parse(
      '$_nominatimUrl/reverse?format=json&lat=${position.latitude}&lon=${position.longitude}',
    );

    final response = await http.get(uri, headers: {'User-Agent': _userAgent});

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['display_name'];
    }
    return null;
  }

  /// Calculate distance between two points in kilometers
  static double calculateDistance(LatLng start, LatLng end) {
    const earthRadius = 6371.0;
    final dLat = _toRadians(end.latitude - start.latitude);
    final dLon = _toRadians(end.longitude - start.longitude);

    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(start.latitude)) *
            cos(_toRadians(end.latitude)) *
            sin(dLon / 2) *
            sin(dLon / 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  /// Estimate travel time based on distance
  static int estimateTravelTime(double distanceKm, {String mode = 'driving'}) {
    final speeds = {'driving': 35, 'cycling': 15, 'walking': 5};
    final speed = speeds[mode] ?? 30;
    final hours = distanceKm / speed;
    return (hours * 60).ceil();
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

  static double _toRadians(double degree) => degree * pi / 180;

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

class RouteInfo {
  final List<LatLng> points;
  final double distance;
  final double duration;

  RouteInfo(
      {required this.points, required this.distance, required this.duration});

  String get distanceKm => '${(distance / 1000).toStringAsFixed(1)} km';
  String get durationMinutes => '${(duration / 60).toStringAsFixed(0)} min';
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
}
