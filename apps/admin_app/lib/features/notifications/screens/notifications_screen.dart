import 'package:flutter/material.dart';
import 'package:staff4dshire_shared/shared.dart';
import 'package:provider/provider.dart';
import 'package:staff4dshire_shared/shared.dart';
import 'package:intl/intl.dart';
import 'package:staff4dshire_shared/shared.dart';
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    // Ensure notifications are loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<NotificationProvider>(context, listen: false);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.currentUser?.id;
      if (userId != null) {
        provider.refreshNotifications(userId);
      }
    });
  }

  Color _getNotificationColor(NotificationType type) {
    switch (type) {
      case NotificationType.success:
        return Colors.green;
      case NotificationType.warning:
        return Colors.orange;
      case NotificationType.error:
        return Colors.red;
      case NotificationType.info:
        return Colors.blue;
    }
  }

  IconData _getNotificationIcon(NotificationType type) {
    switch (type) {
      case NotificationType.success:
        return Icons.check_circle;
      case NotificationType.warning:
        return Icons.warning;
      case NotificationType.error:
        return Icons.error;
      case NotificationType.info:
        return Icons.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final notificationProvider = Provider.of<NotificationProvider>(context);
    
    // Listen to real-time notification stream
    return StreamBuilder<NotificationItem>(
      stream: notificationProvider.notificationStream,
      builder: (context, snapshot) {
        // Rebuild when new notifications arrive
        return Consumer<NotificationProvider>(
          builder: (context, provider, child) {
            final unreadNotifications = provider.unreadNotifications;
            final readNotifications = provider.readNotifications;
            final unreadCount = provider.unreadCount;

            return Scaffold(
              appBar: AppBar(
                title: const Text('Notifications'),
                actions: [
                  if (unreadCount > 0)
                    Consumer<AuthProvider>(
                      builder: (context, authProvider, child) {
                        return TextButton(
                          onPressed: () async {
                            final userId = authProvider.currentUser?.id;
                            await provider.markAllAsRead(userId: userId);
                          },
                          child: const Text('Mark All Read'),
                        );
                      },
                    ),
                ],
              ),
              body: provider.notifications.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.notifications_none,
                            size: 64,
                            color: theme.colorScheme.secondary,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No notifications',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: theme.colorScheme.secondary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'You\'ll see real-time updates here',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.secondary.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: () async {
                        await provider.loadNotifications();
                      },
                      child: ListView(
                        children: [
                          if (unreadNotifications.isNotEmpty) ...[
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  Text(
                                    'Unread ($unreadCount)',
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const Spacer(),
                                  if (unreadCount > 0)
                                    Consumer<AuthProvider>(
                                      builder: (context, authProvider, child) {
                                        return TextButton(
                                          onPressed: () async {
                                            final userId = authProvider.currentUser?.id;
                                            await provider.markAllAsRead(userId: userId);
                                          },
                                          child: const Text('Mark All Read'),
                                        );
                                      },
                                    ),
                                ],
                              ),
                            ),
                            ...unreadNotifications.map((notification) => _buildNotificationCard(
                                  notification,
                                  theme,
                                  false,
                                  provider,
                                )),
                            if (readNotifications.isNotEmpty) const Divider(height: 32),
                          ],
                          if (readNotifications.isNotEmpty) ...[
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Text(
                                'Read',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            ...readNotifications.map((notification) => _buildNotificationCard(
                                  notification,
                                  theme,
                                  true,
                                  provider,
                                )),
                          ],
                        ],
                      ),
                    ),
            );
          },
        );
      },
    );
  }

  Widget _buildNotificationCard(
    NotificationItem notification,
    ThemeData theme,
    bool isRead,
    NotificationProvider provider,
  ) {
    final color = _getNotificationColor(notification.type);
    final icon = _getNotificationIcon(notification.type);

    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (direction) async {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final userId = authProvider.currentUser?.id;
        await provider.deleteNotification(notification.id, userId: userId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Notification deleted'),
            ),
          );
        }
      },
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        color: isRead ? null : theme.colorScheme.primary.withOpacity(0.05),
        child: InkWell(
          onTap: () async {
            if (!notification.isRead) {
              final authProvider = Provider.of<AuthProvider>(context, listen: false);
              final userId = authProvider.currentUser?.id;
              await provider.markAsRead(notification.id, userId: userId);
            }
            // Handle notification tap - navigate to related entity if needed
            if (notification.relatedEntityType != null && 
                notification.relatedEntityId != null) {
              // Navigate based on entity type
              // This can be expanded based on your navigation needs
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color),
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
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                              ),
                            ),
                          ),
                          if (!isRead)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        notification.message,
                        style: theme.textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        DateFormat('MMM dd, yyyy HH:mm').format(notification.timestamp),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.secondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
