import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../config/env_config.dart';

/// Service for sending push notifications via the backend.
/// This is called by other services (OrderService, VendorService, etc.)
/// to trigger notifications when events happen.
class NotificationSenderService {
  /// Send an order status notification to the host.
  /// Uses the convenience endpoint /api/notifications/send-order
  static Future<void> sendOrderNotification({
    required String orderId,
    required String hostUserId,
    required String status,
    String? vendorName,
  }) async {
    try {
      final uri = Uri.parse(
          '${EnvConfig.storageBackendUrl}/api/notifications/send-order');

      debugPrint(
          '[NotificationSender] Sending order notification: $status for order $orderId');

      final response = await http
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              if (EnvConfig.storageApiKey.isNotEmpty)
                'x-api-key': EnvConfig.storageApiKey,
            },
            body: jsonEncode({
              'orderId': orderId,
              'hostUserId': hostUserId,
              'status': status,
              if (vendorName != null) 'vendorName': vendorName,
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        debugPrint('[NotificationSender] ✅ Order notification sent');
      } else {
        debugPrint(
            '[NotificationSender] ❌ Failed (${response.statusCode}): ${response.body}');
      }
    } catch (e) {
      debugPrint('[NotificationSender] ❌ Error sending order notification: $e');
      // Don't throw - notification failure shouldn't break the app flow
    }
  }

  /// Send a custom notification.
  /// Supports multiple targeting options:
  /// - userId: send to a single user
  /// - userIds: send to multiple users
  /// - role: send to all users with a role (host/vendor/rider/admin)
  /// - topic: send to an FCM topic
  static Future<void> sendCustomNotification({
    String? userId,
    List<String>? userIds,
    String? role,
    String? topic,
    required String type,
    required String title,
    required String body,
    String? screen,
    Map<String, String>? data,
    String? imageUrl,
  }) async {
    try {
      final uri =
          Uri.parse('${EnvConfig.storageBackendUrl}/api/notifications/send');

      final payload = {
        if (userId != null) 'userId': userId,
        if (userIds != null) 'userIds': userIds,
        if (role != null) 'role': role,
        if (topic != null) 'topic': topic,
        'payload': {
          'type': type,
          'title': title,
          'body': body,
          if (screen != null) 'screen': screen,
          if (data != null) 'data': data,
          if (imageUrl != null) 'imageUrl': imageUrl,
        },
      };

      debugPrint('[NotificationSender] Sending custom notification: $type');

      final response = await http
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              if (EnvConfig.storageApiKey.isNotEmpty)
                'x-api-key': EnvConfig.storageApiKey,
            },
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        debugPrint('[NotificationSender] ✅ Custom notification sent');
      } else {
        debugPrint(
            '[NotificationSender] ❌ Failed (${response.statusCode}): ${response.body}');
      }
    } catch (e) {
      debugPrint(
          '[NotificationSender] ❌ Error sending custom notification: $e');
      // Don't throw - notification failure shouldn't break the app flow
    }
  }

  /// Send a rider assignment notification to the rider.
  static Future<void> sendRiderAssignmentNotification({
    required String riderId,
    required String orderId,
    required String pickupAddress,
    required String deliveryAddress,
  }) async {
    await sendCustomNotification(
      userId: riderId,
      type: 'rider_assigned',
      title: '🛵 New Delivery Assignment',
      body: 'You have been assigned a new delivery',
      screen: 'rider_deliveries',
      data: {
        'orderId': orderId,
        'pickupAddress': pickupAddress,
        'deliveryAddress': deliveryAddress,
      },
    );
  }

  /// Send an approval notification to a vendor or rider.
  static Future<void> sendApprovalNotification({
    required String userId,
    required String role,
    required bool approved,
  }) async {
    await sendCustomNotification(
      userId: userId,
      type: approved ? 'approval' : 'alert',
      title: approved ? '✅ Account Approved' : '❌ Account Rejected',
      body: approved
          ? 'Your $role account has been approved! You can now login.'
          : 'Your $role application was not approved.',
      screen: approved ? 'login' : null,
    );
  }

  /// Send a promotional notification to all users or a specific role.
  static Future<void> sendPromoNotification({
    String? role,
    required String title,
    required String body,
    String? imageUrl,
    String? screen,
    Map<String, String>? data,
  }) async {
    await sendCustomNotification(
      role: role,
      topic: role == null ? 'all_users' : null,
      type: 'promo',
      title: title,
      body: body,
      imageUrl: imageUrl,
      screen: screen,
      data: data,
    );
  }

  /// Send a chat notification.
  static Future<void> sendChatNotification({
    required String recipientUserId,
    required String senderName,
    required String message,
    required String chatId,
  }) async {
    await sendCustomNotification(
      userId: recipientUserId,
      type: 'chat',
      title: '💬 $senderName',
      body: message,
      screen: 'chat',
      data: {
        'chatId': chatId,
        'senderName': senderName,
      },
    );
  }

  /// Send an alert notification.
  static Future<void> sendAlertNotification({
    String? userId,
    String? role,
    required String title,
    required String body,
    String? screen,
    Map<String, String>? data,
  }) async {
    await sendCustomNotification(
      userId: userId,
      role: role,
      type: 'alert',
      title: title,
      body: body,
      screen: screen,
      data: data,
    );
  }
}
