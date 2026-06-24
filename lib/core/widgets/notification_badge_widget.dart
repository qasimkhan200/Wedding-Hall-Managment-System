import 'package:flutter/material.dart';
import '../services/stored_notification_service.dart';

/// Widget that shows a badge with unread notification count.
/// Useful for displaying in app bars or navigation.
class NotificationBadgeWidget extends StatefulWidget {
  final String userId;
  final VoidCallback? onTap;

  const NotificationBadgeWidget({
    super.key,
    required this.userId,
    this.onTap,
  });

  @override
  State<NotificationBadgeWidget> createState() =>
      _NotificationBadgeWidgetState();
}

class _NotificationBadgeWidgetState extends State<NotificationBadgeWidget> {
  int _unreadCount = 0;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadUnreadCount();
  }

  Future<void> _loadUnreadCount() async {
    setState(() => _loading = true);
    final notifications =
        await StoredNotificationService.getUnreadNotifications(widget.userId);
    if (mounted) {
      setState(() {
        _unreadCount = notifications.length;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Stack(
        children: [
          const Icon(Icons.notifications_outlined),
          if (_unreadCount > 0)
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(10),
                ),
                constraints: const BoxConstraints(
                  minWidth: 16,
                  minHeight: 16,
                ),
                child: Text(
                  _unreadCount > 9 ? '9+' : '$_unreadCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
      onPressed: widget.onTap ?? _loadUnreadCount,
    );
  }
}
