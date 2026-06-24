import 'package:shared_preferences/shared_preferences.dart';

/// Preferences Service
/// Handles persistent storage of user preferences and login state
class PreferencesService {
  static SharedPreferences? _prefs;

  // Keys
  static const String _keyIsLoggedIn = 'is_logged_in';
  static const String _keyUserId = 'user_id';
  static const String _keyUserRole = 'user_role';
  static const String _keyUserEmail = 'user_email';
  static const String _keyUserName = 'user_name';

  /// Initialize SharedPreferences
  static Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
  }

  /// Save login state
  static Future<void> saveLoginState({
    required String userId,
    required String role,
    required String email,
    required String name,
  }) async {
    await _prefs?.setBool(_keyIsLoggedIn, true);
    await _prefs?.setString(_keyUserId, userId);
    await _prefs?.setString(_keyUserRole, role);
    await _prefs?.setString(_keyUserEmail, email);
    await _prefs?.setString(_keyUserName, name);
  }

  /// Clear login state (on logout)
  static Future<void> clearLoginState() async {
    await _prefs?.setBool(_keyIsLoggedIn, false);
    await _prefs?.remove(_keyUserId);
    await _prefs?.remove(_keyUserRole);
    await _prefs?.remove(_keyUserEmail);
    await _prefs?.remove(_keyUserName);
  }

  /// Check if user is logged in
  static bool get isLoggedIn => _prefs?.getBool(_keyIsLoggedIn) ?? false;

  /// Get saved user ID
  static String? get userId => _prefs?.getString(_keyUserId);

  /// Get saved user role
  static String? get userRole => _prefs?.getString(_keyUserRole);

  /// Get saved user email
  static String? get userEmail => _prefs?.getString(_keyUserEmail);

  /// Get saved user name
  static String? get userName => _prefs?.getString(_keyUserName);

  /// Clear all preferences
  static Future<void> clearAll() async {
    await _prefs?.clear();
  }
}
