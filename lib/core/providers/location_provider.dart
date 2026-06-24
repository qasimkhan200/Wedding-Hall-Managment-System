import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

class LocationProvider with ChangeNotifier {
  double? _latitude;
  double? _longitude;
  String? _address;
  bool _isLoading = false;
  String? _error;
  bool _permissionGranted = false;

  double? get latitude => _latitude;
  double? get longitude => _longitude;
  String? get address => _address;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get permissionGranted => _permissionGranted;
  bool get hasLocation => _latitude != null && _longitude != null;

  void setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void setError(String? value) {
    _error = value;
    notifyListeners();
  }

  Future<bool> checkPermission() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setError('Location permissions are denied');
          return false;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setError('Location permissions are permanently denied');
        return false;
      }

      _permissionGranted = true;
      notifyListeners();
      return true;
    } catch (e) {
      setError(e.toString());
      return false;
    }
  }

  Future<bool> getCurrentLocation() async {
    try {
      setLoading(true);
      setError(null);

      // Check permissions first
      bool hasPermission = await checkPermission();
      if (!hasPermission) {
        setLoading(false);
        return false;
      }

      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setError('Location services are disabled');
        setLoading(false);
        return false;
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      _latitude = position.latitude;
      _longitude = position.longitude;

      // For now, set a generic address - we'll implement reverse geocoding later
      _address = 'Current Location';

      setLoading(false);
      return true;
    } catch (e) {
      setError(e.toString());
      setLoading(false);

      // Fallback to mock data for development
      _latitude = 28.6139;
      _longitude = 77.2090;
      _address = 'New Delhi, India (Mock)';

      return false;
    }
  }

  void setLocation({
    required double latitude,
    required double longitude,
    String? address,
  }) {
    _latitude = latitude;
    _longitude = longitude;
    _address = address;
    notifyListeners();
  }

  void setAddress(String address) {
    _address = address;
    notifyListeners();
  }

  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371;

    double dLat = _toRadians(lat2 - lat1);
    double dLon = _toRadians(lon2 - lon1);

    double a = _sin(dLat / 2) * _sin(dLat / 2) +
        _cos(_toRadians(lat1)) *
            _cos(_toRadians(lat2)) *
            _sin(dLon / 2) *
            _sin(dLon / 2);

    double c = 2 * _atan2(_sqrt(a), _sqrt(1 - a));

    return earthRadius * c;
  }

  double _toRadians(double degree) {
    return degree * 3.141592653589793 / 180;
  }

  double _sin(double x) {
    double result = 0;
    double term = x;
    for (int n = 1; n <= 10; n++) {
      result += term;
      term *= -x * x / ((2 * n) * (2 * n + 1));
    }
    return result;
  }

  double _cos(double x) {
    double result = 1;
    double term = 1;
    for (int n = 1; n <= 10; n++) {
      term *= -x * x / ((2 * n - 1) * (2 * n));
      result += term;
    }
    return result;
  }

  double _sqrt(double x) {
    if (x <= 0) return 0;
    double guess = x / 2;
    for (int i = 0; i < 20; i++) {
      guess = (guess + x / guess) / 2;
    }
    return guess;
  }

  double _atan2(double y, double x) {
    if (x > 0) return _atan(y / x);
    if (x < 0 && y >= 0) return _atan(y / x) + 3.141592653589793;
    if (x < 0 && y < 0) return _atan(y / x) - 3.141592653589793;
    if (x == 0 && y > 0) return 3.141592653589793 / 2;
    if (x == 0 && y < 0) return -3.141592653589793 / 2;
    return 0;
  }

  double _atan(double x) {
    if (x > 1) return 3.141592653589793 / 2 - _atan(1 / x);
    if (x < -1) return -3.141592653589793 / 2 - _atan(1 / x);
    double result = 0;
    double term = x;
    for (int n = 0; n < 20; n++) {
      result += term / (2 * n + 1);
      term *= -x * x;
    }
    return result;
  }

  int estimateDeliveryTime(double distance) {
    double averageSpeed = 30;
    int minutes = (distance / averageSpeed * 60).ceil();
    return minutes < 10 ? 10 : minutes;
  }

  // Clear data on logout
  void clearData() {
    _latitude = null;
    _longitude = null;
    _address = null;
    _error = null;
    _isLoading = false;
    notifyListeners();
  }
}
