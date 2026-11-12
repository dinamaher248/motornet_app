part of 'admin_notifications_bloc.dart';

abstract class AdminNotificationsEvent extends Equatable {
  const AdminNotificationsEvent();
  @override
  List<Object?> get props => [];
}

class SendAdminPushEvent extends AdminNotificationsEvent {
  final SendAdminNotificationParams params;
  const SendAdminPushEvent(this.params);
  @override
  List<Object?> get props => [params];
}
