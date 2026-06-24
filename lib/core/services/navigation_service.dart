import 'package:latlong2/latlong.dart';

class NavigationService {
  final Distance _distance = const Distance();

  // Threshold for being considered "off-route" in meters
  static const double offRouteThreshold = 100.0;

  /// Checks if the current user position is off the current route.
  /// Returns true if the user is further than [offRouteThreshold] from the nearest point on the route.
  bool isOffRoute(LatLng userPosition, List<LatLng> routePoints) {
    if (routePoints.isEmpty) return false;

    // Find the minimum distance to the polyline tokens
    // Taking a simplistic approach: distance to nearest vertex.
    // tailored for performance on mobile for now.
    // For more accuracy, we would project point to segment, but vertex check is usually "good enough" for 100m threshold if points are dense enough.
    // OSRM routes are usually detailed.

    double minDistance = double.infinity;

    for (var point in routePoints) {
      final d = _distance.as(LengthUnit.Meter, userPosition, point);
      if (d < minDistance) {
        minDistance = d;
      }
      // optimization: if we find any point within threshold, we are on route
      if (minDistance <= offRouteThreshold) {
        return false;
      }
    }

    return minDistance > offRouteThreshold;
  }

  /// Calculates the distance from the user position to the destination
  double getDistanceToDestination(LatLng userPosition, LatLng destination) {
    return _distance.as(LengthUnit.Meter, userPosition, destination);
  }
}



