import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/env_config.dart';
import 'backend_connectivity_service.dart';

/// Handles FCM token lifecycle: get, refresh, register with backend, delete.
class FcmService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static String? _lastRegisteredUserId;
  static String? _lastRegisteredToken;

  /// Request notification permission and return the FCM token.
  /// Returns null if permission denied or token unavailable.
  static Future<String?> initialize() async {
    // Request permission (required on iOS, recommended on Android 13+)
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    debugPrint('[FCM] Permission status: ${settings.authorizationStatus}');

    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      debugPrint('[FCM] ❌ Permission denied');
      return null;
    }

    // Get the token
    final token = await _messaging.getToken();
    if (token == null) {
      debugPrint(
          '[FCM] ❌ Token is null — check google-services.json and Firebase project setup');
    } else {
      debugPrint(
          '[FCM] ✅ Token obtained (first 20): ${token.substring(0, 20)}...');
    }
    return token;
  }

  /// Register the device token with the VPS backend.
  static Future<void> registerToken({
    required String userId,
    required String fcmToken,
  }) async {
    try {
      // Prevent duplicate registration for same user+token
      if (_lastRegisteredUserId == userId && _lastRegisteredToken == fcmToken) {
        debugPrint(
            '[FCM] ⏭️  Token already registered for this user, skipping');
        return;
      }

      // Check backend connectivity first
      if (!BackendConnectivityService.isConnected) {
        debugPrint(
            '[FCM] ⚠️  Backend not accessible, skipping token registration');
        debugPrint('[FCM] Run connectivity check or start backend server');
        return;
      }

      final platform = Platform.isIOS ? 'ios' : 'android';
      final backendUrl = EnvConfig.storageBackendUrl;
      final uri = Uri.parse('$backendUrl/api/notifications/register-token');

      debugPrint('[FCM] Registering token for user $userId');
      debugPrint('[FCM] Backend URL: $backendUrl');
      debugPrint('[FCM] Token (first 20): ${fcmToken.substring(0, 20)}...');

      final response = await http
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              if (EnvConfig.storageApiKey.isNotEmpty)
                'x-api-key': EnvConfig.storageApiKey,
            },
            body: jsonEncode({
              'userId': userId,
              'fcmToken': fcmToken,
              'platform': platform,
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        _lastRegisteredUserId = userId;
        _lastRegisteredToken = fcmToken;
        debugPrint('[FCM] ✅ Token registered with backend');
      } else {
        debugPrint(
            '[FCM] ❌ Token registration failed (${response.statusCode}): ${response.body}');
      }
    } catch (e) {
      debugPrint('[FCM] ❌ Token registration error: $e');
      debugPrint(
          '[FCM] 💡 TIP: Make sure backend server is running (npm run dev)');
    }
  }

  /// Remove the device token from the backend (call on logout).
  static Future<void> removeToken(String userId) async {
    try {
      final uri = Uri.parse(
          '${EnvConfig.storageBackendUrl}/api/notifications/register-token');

      await http.delete(
        uri,
        headers: {
          'Content-Type': 'application/json',
          if (EnvConfig.storageApiKey.isNotEmpty)
            'x-api-key': EnvConfig.storageApiKey,
        },
        body: jsonEncode({'userId': userId}),
      );

      // Also delete the local FCM token so it won't receive messages
      await _messaging.deleteToken();

      // Clear cached registration
      _lastRegisteredUserId = null;
      _lastRegisteredToken = null;

      debugPrint('[FCM] Token removed');
    } catch (e) {
      debugPrint('[FCM] Token removal error: $e');
    }
  }

  /// Listen for token refreshes and re-register with backend.
  static void listenForTokenRefresh(String userId) {
    _messaging.onTokenRefresh.listen((newToken) async {
      debugPrint('[FCM] Token refreshed');
      await registerToken(userId: userId, fcmToken: newToken);
    });
  }

  /// Subscribe to a topic (e.g. "riders", "vendors").
  static Future<void> subscribeToTopic(String topic) async {
    await _messaging.subscribeToTopic(topic);
    debugPrint('[FCM] Subscribed to topic: $topic');
  }

  /// Unsubscribe from a topic.
  static Future<void> unsubscribeFromTopic(String topic) async {
    await _messaging.unsubscribeFromTopic(topic);
    debugPrint('[FCM] Unsubscribed from topic: $topic');
  }
}
