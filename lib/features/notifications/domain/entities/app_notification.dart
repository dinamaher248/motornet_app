import 'package:equatable/equatable.dart';

class AppNotification extends Equatable {
  final int id;
  final String title;
  final String body;
  final String type;
  final bool isRead;
  final DateTime? createdAt;
  final String? action;
  final String? refId;

  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.isRead,
    this.createdAt,
    this.action,
    this.refId,
  });

  AppNotification copyWith({
    int? id,
    String? title,
    String? body,
    String? type,
    bool? isRead,
    DateTime? createdAt,
    String? action,
    String? refId,
  }) {
    return AppNotification(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      action: action ?? this.action,
      refId: refId ?? this.refId,
    );
  }

  @override
  List<Object?> get props =>
      [id, title, body, type, isRead, createdAt, action, refId];
}

class NotificationsPageResult extends Equatable {
  final List<AppNotification> notifications;
  final int unreadCount;

  const NotificationsPageResult({
    required this.notifications,
    required this.unreadCount,
  });

  @override
  List<Object?> get props => [notifications, unreadCount];
}
