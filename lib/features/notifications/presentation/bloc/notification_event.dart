part of 'notification_bloc.dart';

abstract class NotificationEvent extends Equatable {
  const NotificationEvent();

  @override
  List<Object?> get props => [];
}

class FetchNotificationsEvent extends NotificationEvent {
  const FetchNotificationsEvent();
}

class MarkAsReadEvent extends NotificationEvent {
  final int id;

  const MarkAsReadEvent(this.id);

  @override
  List<Object?> get props => [id];
}

class MarkAllAsReadEvent extends NotificationEvent {
  const MarkAllAsReadEvent();
}
