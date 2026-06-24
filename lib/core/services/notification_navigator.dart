import 'package:flutter/material.dart';
import '../models/notification_model.dart';

/// Handles navigation when a notification is tapped.
/// Reads the `type` and `screen` fields from the payload and routes accordingly.
class NotificationNavigator {
  /// Global navigator key — set this on MaterialApp.navigatorKey
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  static NavigatorState? get _nav => navigatorKey.currentState;

  /// Called by NotificationService when a notification is tapped.
  static void handleTap(NotificationModel notification) {
    final screen = notification.screen;
    final data = notification.data;

    debugPrint(
        '[Nav] Notification tap — type: ${notification.type}, screen: $screen');

    if (screen == null || screen.isEmpty) {
      _routeByType(notification);
      return;
    }

    switch (screen) {
      case 'order_detail':
        final orderId = data['orderId'];
        if (orderId != null) {
          _push(_OrderDetailRoute(orderId: orderId));
        } else {
          _routeByType(notification);
        }
        break;

      case 'orders':
        _routeByType(notification);
        break;

      case 'chat':
        // Push to chat screen if you have one
        _routeByType(notification);
        break;

      case 'home':
        _popToRoot();
        break;

      default:
        _routeByType(notification);
    }
  }

  static void _routeByType(NotificationModel notification) {
    switch (notification.type) {
      case 'order_new':
      case 'order_accepted':
      case 'order_rejected':
      case 'order_ready':
      case 'order_picked_up':
      case 'order_delivered':
      case 'order_cancelled':
      case 'rider_assigned':
        // Navigate to the orders tab — handled by each role's main screen
        _push(_NotificationLandingRoute(notification: notification));
        break;

      case 'alert':
        _showAlertDialog(notification);
        break;

      case 'promo':
      case 'general':
      default:
        // Just show a snackbar for general/promo
        _showSnackbar(notification);
        break;
    }
  }

  static void _push(Widget page) {
    _nav?.push(MaterialPageRoute(builder: (_) => page));
  }

  static void _popToRoot() {
    _nav?.popUntil((route) => route.isFirst);
  }

  static void _showAlertDialog(NotificationModel notification) {
    final context = _nav?.context;
    if (context == null) return;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(notification.title),
        content: Text(notification.body),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  static void _showSnackbar(NotificationModel notification) {
    final context = _nav?.context;
    if (context == null) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              notification.title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            if (notification.body.isNotEmpty)
              Text(notification.body, style: const TextStyle(fontSize: 12)),
          ],
        ),
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

// ─── Placeholder route shown when a notification is tapped ──────────────────
// This screen reads the notification and shows a contextual UI.
// Replace the body with your actual order detail / chat screen as needed.

class _NotificationLandingRoute extends StatelessWidget {
  final NotificationModel notification;
  const _NotificationLandingRoute({required this.notification});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(notification.title),
        leading: const BackButton(),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _NotificationCard(notification: notification),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Go Back'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrderDetailRoute extends StatelessWidget {
  final String orderId;
  const _OrderDetailRoute({required this.orderId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Detail'),
        leading: const BackButton(),
      ),
      body: Center(
        child: Text(
          'Order: $orderId',
          style: const TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}

/// Visual card shown in the notification landing screen.
class _NotificationCard extends StatelessWidget {
  final NotificationModel notification;
  const _NotificationCard({required this.notification});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _typeIcon(notification.type),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    notification.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            if (notification.body.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(notification.body, style: const TextStyle(fontSize: 14)),
            ],
            if (notification.data.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Divider(),
              ...notification.data.entries
                  .where((e) => !['type', 'screen'].contains(e.key))
                  .map(
                    (e) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        children: [
                          Text(
                            '${e.key}: ',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                          Text(e.value, style: const TextStyle(fontSize: 12)),
                        ],
                      ),
                    ),
                  ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _typeIcon(String type) {
    IconData icon;
    Color color;

    if (type.startsWith('order')) {
      icon = Icons.receipt_long;
      color = Colors.blue;
    } else if (type == 'chat') {
      icon = Icons.chat_bubble;
      color = Colors.green;
    } else if (type == 'alert') {
      icon = Icons.warning_amber;
      color = Colors.orange;
    } else if (type == 'promo') {
      icon = Icons.local_offer;
      color = Colors.purple;
    } else {
      icon = Icons.notifications;
      color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }
}
