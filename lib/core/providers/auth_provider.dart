import 'package:flutter/material.dart';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/preferences_service.dart';
import '../services/notification_service.dart';

class AuthProvider with ChangeNotifier {
  UserModel? _user;
  bool _isLoading = false;
  String? _error;
  bool _isAuthenticated = false;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _isAuthenticated;
  String get userRole => _user?.role ?? 'host';

  AuthProvider() {
    _initAuthListener();
  }

  void _initAuthListener() {
    AuthService.authStateChanges().listen((User? firebaseUser) async {
      if (firebaseUser != null) {
        await loadUserData();
      } else {
        _user = null;
        _isAuthenticated = false;
        notifyListeners();
      }
    });
  }

  Future<void> loadUserData() async {
    try {
      final userData = await AuthService.getCurrentUserData();
      if (userData != null) {
        _user = userData;
        _isAuthenticated = true;

        // Register FCM token for auto-login scenarios
        // This handles cases where user is logged in via SharedPreferences
        // but hasn't registered their FCM token yet (e.g., after app restart)
        await NotificationService.login(userData.id);
        await NotificationService.setRole(userData.role);

        // Save login state to SharedPreferences
        await PreferencesService.saveLoginState(
          userId: userData.id,
          role: userData.role,
          email: userData.email,
          name: userData.name,
        );

        notifyListeners();
      }
    } catch (e) {
      // Error loading user data
    }
  }

  void setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void setError(String? value) {
    _error = value;
    notifyListeners();
  }

  Future<bool> signUp({
    required String email,
    required String password,
    required String name,
    required String phone,
    required String role,
  }) async {
    try {
      setLoading(true);
      setError(null);

      _user = await AuthService.signUp(
        email: email,
        password: password,
        name: name,
        phone: phone,
        role: role,
      );

      _isAuthenticated = true;

      // OneSignal Login
      if (_user != null) {
        await NotificationService.login(_user!.id);
        await NotificationService.setRole(_user!.role);
      }

      // Save login state to SharedPreferences (for auto-approved roles)
      if (_user != null && (_user!.role == 'admin' || _user!.role == 'host')) {
        await PreferencesService.saveLoginState(
          userId: _user!.id,
          role: _user!.role,
          email: _user!.email,
          name: _user!.name,
        );
      }

      setLoading(false);
      return true;
    } catch (e) {
      setError(e.toString());
      setLoading(false);
      return false;
    }
  }

  Future<bool> registerVendor({
    required String email,
    required String password,
    required String name,
    required String phone,
    required String businessName,
    required String description,
    required String address,
    required List<String> categories,
    required File? cnicImage,
    required File? logoImage,
    required File? coverImage,
  }) async {
    try {
      setLoading(true);
      setError(null);

      _user = await AuthService.registerVendor(
        email: email,
        password: password,
        name: name,
        phone: phone,
        businessName: businessName,
        description: description,
        address: address,
        categories: categories,
        cnicImage: cnicImage,
        logoImage: logoImage,
        coverImage: coverImage,
      );

      // Note: Vendors are NOT authenticated immediately as they wait for approval (usually)
      // But we set _user so we can show success message.
      // However, per requirements, they are pending approval.

      setLoading(false);
      return true;
    } catch (e) {
      setError(e.toString());
      setLoading(false);
      return false;
    }
  }

  Future<bool> registerRider({
    required String email,
    required String password,
    required String name,
    required String phone,
    required String vehicleType,
    required String vehicleNumber,
    required File? cnicImage,
    required File? licenseImage,
  }) async {
    try {
      setLoading(true);
      setError(null);

      _user = await AuthService.registerRider(
        email: email,
        password: password,
        name: name,
        phone: phone,
        vehicleType: vehicleType,
        vehicleNumber: vehicleNumber,
        cnicImage: cnicImage,
        licenseImage: licenseImage,
      );

      setLoading(false);
      return true;
    } catch (e) {
      setError(e.toString());
      setLoading(false);
      return false;
    }
  }

  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    try {
      setLoading(true);
      setError(null);

      _user = await AuthService.signIn(
        email: email,
        password: password,
      );

      if (_user == null) {
        throw 'Failed to load user data';
      }

      // Role-based approval check:
      // - Admin & Host: Always allowed (no approval check)
      // - Vendor & Rider: Must be approved by admin
      final role = _user!.role;
      if (role == 'vendor' || role == 'rider') {
        if (!_user!.isApproved) {
          await signOut();
          throw 'Your account is pending admin approval';
        }
      }
      // Admin and Host bypass approval check entirely

      // Check if user is active
      if (!_user!.isActive) {
        await signOut();
        throw 'Your account has been deactivated';
      }

      _isAuthenticated = true;

      // OneSignal Login
      await NotificationService.login(_user!.id);
      await NotificationService.setRole(_user!.role);

      // Save login state to SharedPreferences
      await PreferencesService.saveLoginState(
        userId: _user!.id,
        role: _user!.role,
        email: _user!.email,
        name: _user!.name,
      );

      setLoading(false);
      return true;
    } catch (e) {
      setError(e.toString());
      setLoading(false);
      return false;
    }
  }

  Future<void> signOut() async {
    final userId = _user?.id;
    await AuthService.signOut();
    if (userId != null) {
      await NotificationService.logout(userId);
    }

    // Clear login state from SharedPreferences
    await PreferencesService.clearLoginState();

    _user = null;
    _isAuthenticated = false;
    notifyListeners();
  }

  Future<void> updateProfile({
    String? name,
    String? phone,
    String? address,
    double? latitude,
    double? longitude,
    String? profileImage,
  }) async {
    if (_user == null) return;

    try {
      await AuthService.updateProfile(
        userId: _user!.id,
        name: name,
        phone: phone,
        address: address,
        latitude: latitude,
        longitude: longitude,
        profileImage: profileImage,
      );

      _user = _user!.copyWith(
        name: name ?? _user!.name,
        phone: phone ?? _user!.phone,
        address: address ?? _user!.address,
        latitude: latitude ?? _user!.latitude,
        longitude: longitude ?? _user!.longitude,
        profileImage: profileImage ?? _user!.profileImage,
        updatedAt: DateTime.now(),
      );
      notifyListeners();
    } catch (e) {
      setError(e.toString());
    }
  }

  Future<void> resetPassword(String email) async {
    try {
      setLoading(true);
      setError(null);
      await AuthService.resetPassword(email);
      setLoading(false);
    } catch (e) {
      setError(e.toString());
      setLoading(false);
      rethrow;
    }
  }

  void setUser(UserModel user) {
    _user = user;
    _isAuthenticated = true;
    notifyListeners();
  }

  void setUserRole(String role) {
    if (_user != null) {
      _user = _user!.copyWith(role: role);
      notifyListeners();
    }
  }
}
