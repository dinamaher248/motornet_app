import 'package:motorent/data/local/dbTablesHelpers/dbModels/db_models.dart';
import 'package:motorent/features/notifications/domain/entities/app_notification.dart';
import 'package:motorent/services/notification_store.dart';

abstract class NotificationLocalDataSource {
  Future<NotificationsPageResult> getNotifications();

  Future<void> markAsRead(int id);

  Future<void> markAllAsRead();
}

class NotificationLocalDataSourceImpl implements NotificationLocalDataSource {
  final NotificationStore store;

  NotificationLocalDataSourceImpl({NotificationStore? store})
      : store = store ?? NotificationStore.instance;

  @override
  Future<NotificationsPageResult> getNotifications() async {
    final items = await store.getAll();
    final notifications = items
        .where((e) => e.id != null)
        .map(_mapItem)
        .toList();
    final unread = notifications.where((n) => !n.isRead).length;
    return NotificationsPageResult(
      notifications: notifications,
      unreadCount: unread,
    );
  }

  @override
  Future<void> markAsRead(int id) => store.markAsRead(id);

  @override
  Future<void> markAllAsRead() => store.markAllRead();

  AppNotification _mapItem(NotificationItem item) {
    return AppNotification(
      id: item.id ?? 0,
      title: item.title.isNotEmpty ? item.title : 'إشعار',
      body: item.description,
      type: item.action.isNotEmpty ? item.action : 'general',
      isRead: item.isRead,
      createdAt: item.createdAt == null
          ? null
          : DateTime.tryParse(item.createdAt!),
      action: item.action,
      refId: item.refId,
    );
  }
}
