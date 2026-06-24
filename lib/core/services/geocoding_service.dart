import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'venue_intelligence_service.dart';

class GeocodingResult {
  final String displayName;
  final LatLng location;
  final bool isVerifiedVenue;
  final String? venueId;

  GeocodingResult({
    required this.displayName,
    required this.location,
    this.isVerifiedVenue = false,
    this.venueId,
  });
}

class GeocodingService {
  // Nominatim OpenStreetMap API (Free, needs User-Agent)
  static const String _nominatimUrl =
      'https://nominatim.openstreetmap.org/search';
  static const String _userAgent =
      'com.orginize.app'; // Replace with real app ID

  /// Search for a location by query string.
  /// Prioritizes local verified venues.
  static Future<List<GeocodingResult>> searchLocation(String query) async {
    List<GeocodingResult> results = [];

    // 1. Search Local Venues first
    final localVenues = await VenueIntelligenceService.searchVenues(query);
    for (var venue in localVenues) {
      results.add(GeocodingResult(
        displayName: venue.name,
        location: venue.location, // Use main location for search result
        isVerifiedVenue: true,
        venueId: venue.id,
      ));
    }

    // 2. Search Online (Nominatim)
    // Only if local results are few, or always to supplement?
    // Let's always fetch online too for broader coverage, but local stays on top.
    try {
      final onlineResults = await _searchNominatim(query);
      results.addAll(onlineResults);
    } catch (e) {
      print('Nominatim search failed: $e');
    }

    return results;
  }

  static Future<List<GeocodingResult>> _searchNominatim(String query) async {
    // Restrict search to Peshawar area roughly?
    // viewbox=71.3,33.8,71.7,34.1&bounded=1 could focus search
    // For now, simple query + "Peshawar" appended if not present might be safer

    String safeQuery = query;
    // Removed strict Peshawar appending to allow broader search if user types city
    // But for better UX in local app, we can append if it looks like just a street name
    if (!query.toLowerCase().contains('peshawar') &&
        !query.toLowerCase().contains('khyber') &&
        !query.toLowerCase().contains('pakistan')) {
      // Append context only if likely needed, but let's trust Nominatim a bit more or append strictly
      safeQuery = '$query, Peshawar';
    }

    final uri = Uri.parse('$_nominatimUrl?q=$safeQuery&format=json&limit=5');

    final response = await http.get(uri, headers: {
      'User-Agent': _userAgent,
    });

    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      return data.map((item) {
        return GeocodingResult(
          displayName: item['display_name'],
          location: LatLng(
            double.parse(item['lat']),
            double.parse(item['lon']),
          ),
          isVerifiedVenue: false,
        );
      }).toList();
    }
    return [];
  }

  /// Reverse geocode a lat/lng to get an address
  static Future<String?> getAddressFromCoordinates(LatLng pos) async {
    try {
      final uri = Uri.parse(
          'https://nominatim.openstreetmap.org/reverse?format=json&lat=${pos.latitude}&lon=${pos.longitude}');
      final response = await http.get(uri, headers: {
        'User-Agent': _userAgent,
      });

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['display_name'];
      }
    } catch (e) {
      print('Reverse geocoding failed: $e');
    }
    return null;
  }
}
