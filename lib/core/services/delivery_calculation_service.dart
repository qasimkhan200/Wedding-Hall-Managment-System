import 'dart:math';
import '../providers/location_provider.dart';

class DeliveryCalculationService {
  // Average delivery speeds (km/h)
  static const double _bikeSpeed = 25.0;
  static const double _carSpeed = 35.0;
  static const double _walkSpeed = 5.0;

  // Base delivery time in minutes
  static const int _baseDeliveryTime = 10;

  /// Calculate distance between two points using Haversine formula
  static double calculateDistance({
    required double lat1,
    required double lon1,
    required double lat2,
    required double lon2,
  }) {
    const double earthRadius = 6371; // Earth's radius in kilometers

    final double dLat = _toRadians(lat2 - lat1);
    final double dLon = _toRadians(lon2 - lon1);

    final double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) *
            cos(_toRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);

    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadius * c;
  }

  /// Convert degrees to radians
  static double _toRadians(double degrees) {
    return degrees * pi / 180;
  }

  /// Format distance for display
  static String formatDistance(double distanceKm) {
    if (distanceKm < 1) {
      return '${(distanceKm * 1000).round()} m';
    } else {
      return '${distanceKm.toStringAsFixed(1)} km';
    }
  }

  /// Calculate estimated delivery time based on distance and vehicle type
  static int calculateDeliveryTime({
    required double distanceKm,
    String vehicleType = 'bike',
    int preparationTime = 15, // Time for vendor to prepare order
  }) {
    double speed;

    switch (vehicleType.toLowerCase()) {
      case 'car':
        speed = _carSpeed;
        break;
      case 'walk':
        speed = _walkSpeed;
        break;
      case 'bike':
      default:
        speed = _bikeSpeed;
        break;
    }

    // Calculate travel time in minutes
    final int travelTime = ((distanceKm / speed) * 60).ceil();

    // Add preparation time and base delivery time
    final int totalTime = preparationTime + travelTime + _baseDeliveryTime;

    // Minimum delivery time is 20 minutes
    return totalTime < 20 ? 20 : totalTime;
  }

  /// Format delivery time for display
  static String formatDeliveryTime(int minutes) {
    if (minutes < 60) {
      return '$minutes min';
    } else {
      final int hours = minutes ~/ 60;
      final int remainingMinutes = minutes % 60;
      if (remainingMinutes == 0) {
        return '${hours}h';
      } else {
        return '${hours}h ${remainingMinutes}m';
      }
    }
  }

  /// Get delivery time range (e.g., "25-35 min")
  static String getDeliveryTimeRange(int estimatedMinutes) {
    final int minTime = (estimatedMinutes * 0.8).round();
    final int maxTime = (estimatedMinutes * 1.2).round();

    if (minTime < 60 && maxTime < 60) {
      return '$minTime-$maxTime min';
    } else {
      return formatDeliveryTime(estimatedMinutes);
    }
  }

  /// Calculate delivery fee based on distance
  static double calculateDeliveryFee({
    required double distanceKm,
    double baseFee = 30.0,
    double perKmRate = 10.0,
  }) {
    if (distanceKm <= 2.0) {
      return baseFee;
    } else {
      return baseFee + ((distanceKm - 2.0) * perKmRate);
    }
  }

  /// Get vendor distance from user location
  static double? getVendorDistance({
    required double vendorLat,
    required double vendorLon,
    required LocationProvider locationProvider,
  }) {
    if (!locationProvider.hasLocation) return null;

    return calculateDistance(
      lat1: locationProvider.latitude!,
      lon1: locationProvider.longitude!,
      lat2: vendorLat,
      lon2: vendorLon,
    );
  }

  /// Get rider distance from pickup location
  static double? getRiderDistance({
    required double riderLat,
    required double riderLon,
    required double pickupLat,
    required double pickupLon,
  }) {
    return calculateDistance(
      lat1: riderLat,
      lon1: riderLon,
      lat2: pickupLat,
      lon2: pickupLon,
    );
  }

  /// Calculate estimated arrival time
  static DateTime calculateEstimatedArrival(int deliveryMinutes) {
    return DateTime.now().add(Duration(minutes: deliveryMinutes));
  }

  /// Format estimated arrival time
  static String formatEstimatedArrival(DateTime arrivalTime) {
    final now = DateTime.now();
    final difference = arrivalTime.difference(now);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} min';
    } else {
      final hours = difference.inHours;
      final minutes = difference.inMinutes % 60;
      return '${hours}h ${minutes}m';
    }
  }
}
