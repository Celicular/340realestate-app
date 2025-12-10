import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../models/notification_model.dart';
import '../services/notification_service.dart';
import '../providers/auth_provider.dart';
import 'package:timeago/timeago.dart' as timeago;

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final NotificationService _notificationService = NotificationService();

  IconData _getIconForType(String iconType) {
    switch (iconType) {
      case 'home':
        return Icons.home;
      case 'trending_down':
        return Icons.trending_down;
      case 'calendar':
      case 'calendar_today':
        return Icons.calendar_today;
      case 'message':
        return Icons.message;
      case 'add_circle':
        return Icons.add_circle;
      case 'favorite':
        return Icons.favorite;
      case 'assessment':
        return Icons.assessment;
      default:
        return Icons.notifications;
    }
  }

  Color _getColorForType(String type) {
    switch (type) {
      case 'price_drop':
        return Colors.green;
      case 'new_match':
      case 'agent_response':
        return AppTheme.primaryColor;
      case 'viewing':
        return Colors.orange;
      case 'new_listing':
        return Colors.blue;
      case 'favorite_update':
        return Colors.red;
      case 'market_report':
        return Colors.purple;
      default:
        return AppTheme.primaryColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final userId = authProvider.user?.uid;

    if (userId == null) {
      return Scaffold(
        appBar: AppBar(
          elevation: 0,
          title: Text(
            'Notifications',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.login, size: 80, color: AppTheme.textTertiary),
              const SizedBox(height: 16),
              Text(
                'Please sign in to view notifications',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Notifications',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await _notificationService.markAllAsRead(userId);
            },
            child: const Text(
              'Mark all read',
              style: TextStyle(color: AppTheme.primaryColor),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: StreamBuilder<List<NotificationModel>>(
          stream: _notificationService.getUserNotifications(userId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline,
                        size: 80, color: Colors.red),
                    const SizedBox(height: 16),
                    Text(
                      'Error loading notifications',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      snapshot.error.toString(),
                      style: Theme.of(context).textTheme.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }

            final notifications = snapshot.data ?? [];

            if (notifications.isEmpty) {
              return _buildEmptyState(context);
            }

            return ListView.builder(
              padding: const EdgeInsets.all(AppTheme.spacingMedium),
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final notification = notifications[index];
                return _buildNotificationItem(context, notification);
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingXLarge),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.notifications_none,
              size: 80,
              color: AppTheme.textTertiary,
            ),
            const SizedBox(height: AppTheme.spacingLarge),
            Text(
              'No Notifications',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: AppTheme.spacingSmall),
            Text(
              'You\'re all caught up! New notifications will appear here.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationItem(
      BuildContext context, NotificationModel notification) {
    final icon = _getIconForType(notification.iconType);
    final color = _getColorForType(notification.type);
    final timeAgo = timeago.format(notification.timestamp, locale: 'en_short');

    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingMedium),
      decoration: BoxDecoration(
        color: notification.isRead
            ? Theme.of(context).colorScheme.surface
            : AppTheme.primaryColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
        border: Border.all(
          color: notification.isRead
              ? Theme.of(context).colorScheme.outline
              : AppTheme.primaryColor.withValues(alpha: 0.3),
        ),
      ),
      child: Dismissible(
        key: Key(notification.id),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          decoration: BoxDecoration(
            color: Colors.red,
            borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
          ),
          child: const Icon(Icons.delete, color: Colors.white),
        ),
        onDismissed: (direction) {
          _notificationService.deleteNotification(notification.id);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Notification deleted')),
          );
        },
        child: ListTile(
          contentPadding: const EdgeInsets.all(AppTheme.spacingMedium),
          leading: Container(
            padding: const EdgeInsets.all(AppTheme.spacingSmall),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  notification.title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: notification.isRead
                            ? FontWeight.normal
                            : FontWeight.w600,
                      ),
                ),
              ),
              if (!notification.isRead)
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppTheme.primaryColor,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppTheme.spacingSmall),
              Text(
                notification.message,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
              ),
              const SizedBox(height: AppTheme.spacingSmall),
              Text(
                timeAgo,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textTertiary,
                    ),
              ),
            ],
          ),
          onTap: () async {
            if (!notification.isRead) {
              await _notificationService.markAsRead(notification.id);
            }
            // TODO: Navigate to related property if relatedPropertyId is not null
          },
        ),
      ),
    );
  }
}
