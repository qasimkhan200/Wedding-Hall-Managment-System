import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'peshawar_traffic_service.dart';

class MapRoute {
  final List<LatLng> points;
  final double duration; // in minutes
  final double distance; // in meters

  MapRoute({
    required this.points,
    required this.duration,
    required this.distance,
  });
}

class MapService {
  // Using public OSRM server for demo. In production, use your own instance.
  static const String _baseUrl =
      'http://router.project-osrm.org/route/v1/driving';

  Future<MapRoute> getRoute(LatLng start, LatLng end) async {
    final url =
        '$_baseUrl/${start.longitude},${start.latitude};${end.longitude},${end.latitude}?overview=full&geometries=polyline';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['routes'] == null || (data['routes'] as List).isEmpty) {
          throw Exception('No route found');
        }

        final route = data['routes'][0];
        final geometry = route['geometry'] as String;
        final durationSeconds = (route['duration'] as num?)?.toDouble() ?? 0.0;
        final distanceMeters = (route['distance'] as num?)?.toDouble() ?? 0.0;

        final points = _decodePolyline(geometry);

        // Apply Peshawar Traffic Multiplier
        // We check the destination primarily as that determines the traffic conditions near venue
        final multiplier = PeshawarTrafficService.getTrafficMultiplier(end);
        final adjustedDurationMinutes = (durationSeconds * multiplier) / 60;

        return MapRoute(
          points: points,
          duration: adjustedDurationMinutes,
          distance: distanceMeters,
        );
      } else {
        throw Exception('Failed to load route: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching route: $e');
    }
  }

  // Basic Polyline Decoder (Google Polyline Algorithm)
  // flutter_map or other libs might have this built-in, but keeping it standalone to avoid extra dependencies if possible.
  // Actually, latlong2 doesn't have a decoder. We can implement a simple one.
  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> poly = [];
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
}
