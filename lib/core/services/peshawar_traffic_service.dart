import 'package:latlong2/latlong.dart';

class PeshawarTrafficService {
  // Define known high-traffic zones with simple center point and radius (in km approx)
  static final _universityRoad = LatLng(34.0000, 71.4800); // Approx center
  static final _oldCity = LatLng(34.0120, 71.5700);
  static final _ringRoad = LatLng(33.9800, 71.5500);

  // Multipliers
  static const double _universityRoadMultiplier = 1.8;
  static const double _oldCityMultiplier = 2.0;
  static const double _ringRoadMultiplier = 1.2;
  static const double _fridayPrayerMultiplier = 1.5; // 1-2 PM
  static const double _weddingRushMultiplier = 1.4; // 6-10 PM

  static double getTrafficMultiplier(LatLng location) {
    double multiplier = 1.0;
    final now = DateTime.now();

    // 1. Time-based Global adjustments

    // Friday Prayers (1 PM - 2:30 PM) on Friday
    if (now.weekday == DateTime.friday) {
      if (now.hour == 13 || (now.hour == 14 && now.minute <= 30)) {
        multiplier *= _fridayPrayerMultiplier;
      }
    }

    // Wedding Rush (Evenings 6 PM - 10 PM)
    // Especially relevant for Peshawar where weddings are huge
    if (now.hour >= 18 && now.hour <= 22) {
      multiplier *= _weddingRushMultiplier;
    }

    // 2. Location-based adjustments

    // Check University Road (Radius ~2km)
    if (_isNear(location, _universityRoad, 0.02)) {
      multiplier *= _universityRoadMultiplier;
    }
    // Check Old City (Congested narrow streets)
    else if (_isNear(location, _oldCity, 0.02)) {
      multiplier *= _oldCityMultiplier;
    }
    // Check Ring Road
    else if (_isNear(location, _ringRoad, 0.03)) {
      multiplier *= _ringRoadMultiplier;
    }

    return multiplier;
  }

  // Simple distance approximation (Euclidean on lat/lng is okay for small distances locally)
  // 0.01 degrees is roughly 1.1km
  static bool _isNear(LatLng p1, LatLng center, double thresholdDegrees) {
    final dLat = (p1.latitude - center.latitude).abs();
    final dLng = (p1.longitude - center.longitude).abs();
    // Use simple Manhattan distance check for speed, or euclidean squared
    return (dLat * dLat + dLng * dLng) < (thresholdDegrees * thresholdDegrees);
  }
}
