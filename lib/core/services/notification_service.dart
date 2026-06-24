import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../models/notification_model.dart';
import 'fcm_service.dart';
import 'stored_notification_service.dart';

// ─── Background message handler (top-level, required by FCM) ──────────────
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Firebase is already initialized by the time this runs.
  // We just need to show a local notification if needed.
  // The system tray notification is shown automatically by FCM for
  // data+notification messages. For data-only messages we show one manually.
  debugPrint('[FCM] Background message: ${message.messageId}');
}

/// Central notification service.
/// Handles FCM setup, local notification display, and routing callbacks.
class NotificationService {
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  /// Callback invoked when user taps a notification.
  /// Set this from main.dart or a root widget.
  static void Function(NotificationModel)? onNotificationTap;

  // ─── Android notification channels ──────────────────────────────────────

  static const _channelOrders = AndroidNotificationChannel(
    'orders',
    'Order Updates',
    description: 'Notifications about your order status',
    importance: Importance.high,
    playSound: true,
  );

  static const _channelChat = AndroidNotificationChannel(
    'chat',
    'Chat Messages',
    description: 'New chat messages',
    importance: Importance.high,
    playSound: true,
  );

  static const _channelAlerts = AndroidNotificationChannel(
    'alerts',
    'Alerts',
    description: 'Important alerts',
    importance: Importance.max,
    playSound: true,
  );

  static const _channelPromo = AndroidNotificationChannel(
    'promotions',
    'Promotions',
    description: 'Promotional offers',
    importance: Importance.defaultImportance,
    playSound: false,
  );

  static const _channelGeneral = AndroidNotificationChannel(
    'general',
    'General',
    description: 'General notifications',
    importance: Importance.defaultImportance,
  );

  // ─── Init ────────────────────────────────────────────────────────────────

  static Future<void> init() async {
    // Register background handler
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // Create Android channels
    final androidPlugin =
        _localNotifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin != null) {
      await androidPlugin.createNotificationChannel(_channelOrders);
      await androidPlugin.createNotificationChannel(_channelChat);
      await androidPlugin.createNotificationChannel(_channelAlerts);
      await androidPlugin.createNotificationChannel(_channelPromo);
      await androidPlugin.createNotificationChannel(_channelGeneral);
    }

    // Initialize local notifications
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: false, // We request via FCM
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    await _localNotifications.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
      onDidReceiveNotificationResponse: _onLocalNotificationTap,
    );

    // Handle foreground FCM messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle notification tap when app is in background (not terminated)
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    // Handle notification tap when app was terminated
    final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      // Delay slightly to let the app finish building
      Future.delayed(const Duration(milliseconds: 500), () {
        _handleNotificationTap(initialMessage);
      });
    }

    // iOS foreground presentation options
    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
      alert: false, // We show our own via flutter_local_notifications
      badge: true,
      sound: false,
    );

    debugPrint('[FCM] NotificationService initialized');
  }

  // ─── Token management ────────────────────────────────────────────────────

  /// Call after login — gets FCM token and registers it with the backend.
  static Future<void> login(String userId) async {
    final token = await FcmService.initialize();
    if (token != null) {
      await FcmService.registerToken(userId: userId, fcmToken: token);
      FcmService.listenForTokenRefresh(userId);
    }
    // Subscribe to role-agnostic topic
    await FcmService.subscribeToTopic('all_users');

    // Check for stored notifications that were missed while offline
    if (onNotificationTap != null) {
      await StoredNotificationService.checkAndShowUnreadOnLogin(
        userId,
        onNotificationTap!,
      );
    }
  }

  /// Call after setting role — subscribes to role topic.
  static Future<void> setRole(String role) async {
    // Unsubscribe from all role topics first
    for (final r in ['host', 'vendor', 'rider', 'admin']) {
      await FcmService.unsubscribeFromTopic(r);
    }
    await FcmService.subscribeToTopic(role);
    debugPrint('[FCM] Subscribed to role topic: $role');
  }

  /// Call on logout.
  static Future<void> logout(String userId) async {
    await FcmService.removeToken(userId);
    await FcmService.unsubscribeFromTopic('all_users');
    for (final r in ['host', 'vendor', 'rider', 'admin']) {
      await FcmService.unsubscribeFromTopic(r);
    }
  }

  // ─── Message handlers ────────────────────────────────────────────────────

  static void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('[FCM] Foreground message: ${message.messageId}');
    final notification = _parseMessage(message);
    _showLocalNotification(notification, message.messageId.hashCode);
  }

  static void _handleNotificationTap(RemoteMessage message) {
    debugPrint('[FCM] Notification tapped: ${message.messageId}');
    final notification = _parseMessage(message);
    onNotificationTap?.call(notification);
  }

  static void _onLocalNotificationTap(NotificationResponse response) {
    debugPrint('[FCM] Local notification tapped: ${response.payload}');
    if (response.payload == null) return;

    // Payload is stored as "type|screen|data_json"
    final parts = response.payload!.split('|');
    if (parts.length < 2) return;

    final notification = NotificationModel(
      type: parts[0],
      title: '',
      body: '',
      screen: parts[1].isNotEmpty ? parts[1] : null,
      data: parts.length > 2 ? _parseDataPayload(parts[2]) : {},
    );
    onNotificationTap?.call(notification);
  }

  // ─── Local notification display ──────────────────────────────────────────

  static Future<void> _showLocalNotification(
    NotificationModel notification,
    int id,
  ) async {
    final channel = _channelForType(notification.type);
    final style = _styleForType(notification);

    final androidDetails = AndroidNotificationDetails(
      channel.id,
      channel.name,
      channelDescription: channel.description,
      importance: channel.importance,
      priority: Priority.high,
      styleInformation: style,
      icon: '@mipmap/ic_launcher',
      color: const Color(0xFF6C63FF), // AppColors.primary
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final payload =
        '${notification.type}|${notification.screen ?? ''}|${_encodeData(notification.data)}';

    await _localNotifications.show(
      id,
      notification.title,
      notification.body,
      NotificationDetails(android: androidDetails, iOS: iosDetails),
      payload: payload,
    );
  }

  static AndroidNotificationChannel _channelForType(String type) {
    if (type.startsWith('order')) return _channelOrders;
    if (type == 'chat') return _channelChat;
    if (type == 'alert') return _channelAlerts;
    if (type == 'promo') return _channelPromo;
    return _channelGeneral;
  }

  static StyleInformation _styleForType(NotificationModel n) {
    // Big picture style for promo notifications with images
    if (n.type == 'promo' && n.imageUrl != null) {
      return BigPictureStyleInformation(
        DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
        largeIcon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
        contentTitle: n.title,
        summaryText: n.body,
        htmlFormatContentTitle: false,
        htmlFormatSummaryText: false,
      );
    }

    // Big text style for long messages
    return BigTextStyleInformation(
      n.body,
      contentTitle: n.title,
      htmlFormatBigText: false,
      htmlFormatContentTitle: false,
    );
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────

  static NotificationModel _parseMessage(RemoteMessage message) {
    final data = Map<String, dynamic>.from(message.data);

    // Merge notification block title/body into data if present
    if (message.notification != null) {
      data['title'] = message.notification!.title ?? data['title'] ?? '';
      data['body'] = message.notification!.body ?? data['body'] ?? '';
      if (message.notification!.android?.imageUrl != null) {
        data['imageUrl'] = message.notification!.android!.imageUrl!;
      }
    }

    return NotificationModel.fromData(data);
  }

  static Map<String, String> _parseDataPayload(String encoded) {
    try {
      final pairs = encoded.split(',');
      final map = <String, String>{};
      for (final pair in pairs) {
        final idx = pair.indexOf('=');
        if (idx > 0) {
          map[pair.substring(0, idx)] = pair.substring(idx + 1);
        }
      }
      return map;
    } catch (_) {
      return {};
    }
  }

  static String _encodeData(Map<String, String> data) {
    return data.entries.map((e) => '${e.key}=${e.value}').join(',');
  }
}
