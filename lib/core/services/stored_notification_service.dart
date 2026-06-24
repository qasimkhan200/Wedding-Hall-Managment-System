import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/env_config.dart';
import '../models/notification_model.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Service to fetch and manage stored notifications from Firestore.
/// These are notifications that couldn't be delivered via FCM because
/// the user was offline or didn't have a registered token.
class StoredNotificationService {
  /// Fetch unread notifications for a user.
  static Future<List<StoredNotification>> getUnreadNotifications(
      String userId) async {
    try {
      final uri = Uri.parse(
          '${EnvConfig.storageBackendUrl}/api/notifications/unread/$userId');

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          if (EnvConfig.storageApiKey.isNotEmpty)
            'x-api-key': EnvConfig.storageApiKey,
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final notifications = (data['notifications'] as List)
            .map((n) => StoredNotification.fromMap(n))
            .toList();
        debugPrint(
            '[StoredNotifications] ✅ Fetched ${notifications.length} unread notifications');
        return notifications;
      } else {
        debugPrint(
            '[StoredNotifications] ❌ Failed to fetch (${response.statusCode}): ${response.body}');
        return [];
      }
    } catch (e) {
      debugPrint('[StoredNotifications] ❌ Error fetching: $e');
      return [];
    }
  }

  /// Mark notifications as read.
  static Future<bool> markAsRead(List<String> notificationIds) async {
    if (notificationIds.isEmpty) return true;

    try {
      final uri = Uri.parse(
          '${EnvConfig.storageBackendUrl}/api/notifications/mark-read');

      final response = await http
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              if (EnvConfig.storageApiKey.isNotEmpty)
                'x-api-key': EnvConfig.storageApiKey,
            },
            body: jsonEncode({'notificationIds': notificationIds}),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        debugPrint(
            '[StoredNotifications] ✅ Marked ${notificationIds.length} as read');
        return true;
      } else {
        debugPrint(
            '[StoredNotifications] ❌ Failed to mark read (${response.statusCode}): ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('[StoredNotifications] ❌ Error marking read: $e');
      return false;
    }
  }

  /// Check for unread notifications on login and show them.
  static Future<void> checkAndShowUnreadOnLogin(
    String userId,
    Function(NotificationModel) onNotificationTap,
  ) async {
    final notifications = await getUnreadNotifications(userId);

    if (notifications.isEmpty) {
      debugPrint('[StoredNotifications] No unread notifications');
      return;
    }

    debugPrint(
        '[StoredNotifications] 📬 Found ${notifications.length} unread notifications');

    // Show each notification as a local notification
    for (int i = 0; i < notifications.length; i++) {
      final notification = notifications[i];
      await _showStoredNotification(notification, i);
    }

    // Mark them as read after showing
    final ids = notifications.map((n) => n.id).toList();
    await markAsRead(ids);

    debugPrint(
        '[StoredNotifications] ✅ Displayed ${notifications.length} missed notifications');
  }

  /// Show a stored notification as a local notification.
  static Future<void> _showStoredNotification(
    StoredNotification notification,
    int index,
  ) async {
    try {
      // Import flutter_local_notifications
      final FlutterLocalNotificationsPlugin localNotifications =
          FlutterLocalNotificationsPlugin();

      const androidDetails = AndroidNotificationDetails(
        'orders',
        'Order Updates',
        channelDescription: 'Notifications about your order status',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        color: Color(0xFF6C63FF),
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      await localNotifications.show(
        1000 + index, // Use unique IDs starting from 1000
        notification.title,
        notification.body,
        const NotificationDetails(android: androidDetails, iOS: iosDetails),
      );

      debugPrint('[StoredNotifications] 📱 Showed: ${notification.title}');
    } catch (e) {
      debugPrint('[StoredNotifications] ❌ Error showing notification: $e');
    }
  }
}

/// Model for stored notifications from Firestore.
class StoredNotification {
  final String id;
  final String userId;
  final String type;
  final String title;
  final String body;
  final String? screen;
  final Map<String, dynamic> data;
  final bool read;
  final DateTime? createdAt;

  StoredNotification({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.body,
    this.screen,
    required this.data,
    required this.read,
    this.createdAt,
  });

  factory StoredNotification.fromMap(Map<String, dynamic> map) {
    return StoredNotification(
      id: map['id']?.toString() ?? '',
      userId: map['userId']?.toString() ?? '',
      type: map['type']?.toString() ?? 'general',
      title: map['title']?.toString() ?? '',
      body: map['body']?.toString() ?? '',
      screen: map['screen']?.toString(),
      data: Map<String, dynamic>.from(map['data'] ?? {}),
      read: map['read'] == true,
      createdAt: map['createdAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(
              (map['createdAt']['_seconds'] ?? 0) * 1000)
          : null,
    );
  }

  /// Convert to NotificationModel for navigation.
  NotificationModel toNotificationModel() {
    return NotificationModel(
      type: type,
      title: title,
      body: body,
      screen: screen,
      data: data.map((k, v) => MapEntry(k, v.toString())),
    );
  }
}
