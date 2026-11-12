part of 'notification_bloc.dart';

abstract class NotificationState extends Equatable {
  const NotificationState();

  @override
  List<Object?> get props => [];
}

class NotificationInitial extends NotificationState {
  const NotificationInitial();
}

class NotificationLoading extends NotificationState {
  const NotificationLoading();
}

class NotificationsLoadedSuccess extends NotificationState {
  final List<AppNotification> notifications;
  final int unreadCount;

  const NotificationsLoadedSuccess({
    required this.notifications,
    required this.unreadCount,
  });

  bool get hasUnread => unreadCount > 0;

  NotificationsLoadedSuccess copyWith({
    List<AppNotification>? notifications,
    int? unreadCount,
  }) {
    return NotificationsLoadedSuccess(
      notifications: notifications ?? this.notifications,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }

  @override
  List<Object?> get props => [notifications, unreadCount];
}

class NotificationError extends NotificationState {
  final String message;

  const NotificationError(this.message);

  @override
  List<Object?> get props => [message];
}
