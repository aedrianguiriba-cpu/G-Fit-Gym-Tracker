import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../models/notification.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  int _currentPage = 0;
  static const int _itemsPerPage = 10;

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final notifications = appState.notifications;
    final unreadCount = notifications.where((n) => !n.isRead).length;

    // Calculate pagination
    final totalItems = notifications.length;
    final totalPages = (totalItems / _itemsPerPage).ceil();
    final startIndex = _currentPage * _itemsPerPage;
    final endIndex = (startIndex + _itemsPerPage).clamp(0, totalItems);
    final paginatedNotifications = totalItems > 0
        ? notifications.sublist(startIndex, endIndex < totalItems ? endIndex : totalItems)
        : <AppNotification>[];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (unreadCount > 0)
            TextButton(
              onPressed: () => appState.markAllNotificationsAsRead(),
              child: const Text(
                'Mark all read',
                style: TextStyle(color: Color(0xFF3B82F6)),
              ),
            ),
        ],
      ),
      body: notifications.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_off_outlined,
                    size: 64,
                    color: Colors.white.withOpacity(0.2),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No notifications',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white.withOpacity(0.6),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'You\'re all caught up!',
                    style: TextStyle(color: Colors.white.withOpacity(0.4)),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: paginatedNotifications.length + 1,
              itemBuilder: (context, index) {
                if (index == paginatedNotifications.length) {
                  return Container(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          onPressed: _currentPage > 0
                              ? () => setState(() => _currentPage--)
                              : null,
                          icon: const Icon(Icons.arrow_back),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Page ${_currentPage + 1} of ${totalPages.toString()}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 12),
                        IconButton(
                          onPressed: _currentPage < totalPages - 1
                              ? () => setState(() => _currentPage++)
                              : null,
                          icon: const Icon(Icons.arrow_forward),
                        ),
                      ],
                    ),
                  );
                }
                final notification = paginatedNotifications[index];
                return _NotificationCard(
                  notification: notification,
                  onTap: () => appState.markNotificationAsRead(notification.id),
                  onDismiss: () => appState.removeNotification(notification.id),
                );
              },
            ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final AppNotification notification;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  const _NotificationCard({
    required this.notification,
    required this.onTap,
    required this.onDismiss,
  });

  IconData _getIcon() {
    switch (notification.type) {
      case NotificationType.workout:
        return Icons.fitness_center;
      case NotificationType.achievement:
        return Icons.emoji_events;
      case NotificationType.reminder:
        return Icons.notifications_active;
      case NotificationType.social:
        return Icons.people;
    }
  }

  Color _getColor() {
    switch (notification.type) {
      case NotificationType.workout:
        return const Color(0xFF3B82F6);
      case NotificationType.achievement:
        return const Color(0xFFFBBF24);
      case NotificationType.reminder:
        return const Color(0xFF8B5CF6);
      case NotificationType.social:
        return const Color(0xFF10B981);
    }
  }

  String _getTimeAgo() {
    final now = DateTime.now();
    final difference = now.difference(notification.timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${difference.inDays ~/ 7}w ago';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDismiss(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.red.withOpacity(0.2),
        child: const Icon(Icons.delete_outline, color: Colors.red),
      ),
      child: InkWell(
        onTap: notification.isRead ? null : onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: notification.isRead
                ? const Color(0xFF1A1A1A)
                : const Color(0xFF1A1A1A).withOpacity(0.8),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: notification.isRead
                  ? Colors.white.withOpacity(0.05)
                  : _getColor().withOpacity(0.3),
              width: notification.isRead ? 1 : 2,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _getColor().withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getIcon(),
                  color: _getColor(),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: notification.isRead
                                  ? FontWeight.w500
                                  : FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        if (!notification.isRead)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: _getColor(),
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.message,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.6),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _getTimeAgo(),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.4),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
