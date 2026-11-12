import 'dart:async';

import '../data/local/dbTablesHelpers/NotificationDb.dart';
import '../data/local/dbTablesHelpers/dbModels/db_models.dart';
import '../utils/notification_kind.dart';
import 'package:motorent/features/notifications/domain/entities/app_notification.dart';

class NotificationStore {
  NotificationStore._();

  static final NotificationStore instance = NotificationStore._();

  final NotificationDb _db = NotificationDb();
  final StreamController<void> _changes = StreamController<void>.broadcast();

  Stream<void> get changes => _changes.stream;

  /// Notify listeners (badge / screens) after inbox changes.
  void notifyChanged() {
    if (!_changes.isClosed) {
      _changes.add(null);
    }
  }

  static String serverRefId(int serverId) => 'server:$serverId';

  Future<void> saveFromPush({
    required String title,
    required String body,
    String action = '',
    String topic = 'motorent',
    String? refId,
    String? url,
  }) async {
    final normalizedAction = NotificationKind.normalize(action);
    final resolvedRef = (refId ?? '').trim().isNotEmpty
        ? refId!.trim()
        : (url ?? '').trim().isNotEmpty
            ? url!.trim()
            : null;

    await _db.insertItem(
      NotificationItem(
        title: title.isNotEmpty ? title : 'إشعار',
        description: body,
        action: normalizedAction,
        topic: topic,
        refId: resolvedRef,
        createdAt: DateTime.now().toIso8601String(),
        isRead: false,
      ),
    );
    notifyChanged();
  }

  /// Upsert server-side inbox rows into local SQLite so the list always shows them.
  Future<void> syncFromServer(
    List<AppNotification> remote, {
    bool notify = true,
  }) async {
    for (final n in remote) {
      if (n.id <= 0) continue;
      final ref = serverRefId(n.id);
      final existingId = await _db.findIdByRef(ref);
      await _db.insertItem(
        NotificationItem(
          id: existingId,
          title: n.title.isNotEmpty ? n.title : 'إشعار',
          description: n.body,
          action: NotificationKind.normalize(n.action ?? n.type),
          topic: 'server',
          refId: ref,
          createdAt:
              n.createdAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
          isRead: n.isRead,
        ),
      );
    }
    if (notify) notifyChanged();
  }

  Future<List<NotificationItem>> getAll() async {
    final items = await _db.getAllItems();
    items.sort((a, b) => (b.id ?? 0).compareTo(a.id ?? 0));
    return items;
  }

  Future<int> unreadCount() => _db.unreadCount();

  Future<void> markAsRead(int id) async {
    await _db.markAsRead(id);
    notifyChanged();
  }

  Future<void> markServerAsRead(int serverId) async {
    await _db.markAsReadByRef(serverRefId(serverId));
    notifyChanged();
  }

  Future<void> markAllRead() async {
    await _db.markAllRead();
    notifyChanged();
  }

  Future<void> clearAll() async {
    await _db.clear();
    notifyChanged();
  }

  Future<void> remove(int id) async {
    await _db.removeItem(id);
    notifyChanged();
  }
}
