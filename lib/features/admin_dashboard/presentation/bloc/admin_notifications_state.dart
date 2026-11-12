part of 'admin_notifications_bloc.dart';

enum AdminNotificationsStatus { initial, sending, success, failure }

class AdminNotificationsState extends Equatable {
  final AdminNotificationsStatus status;
  final String? message;

  const AdminNotificationsState({
    this.status = AdminNotificationsStatus.initial,
    this.message,
  });

  AdminNotificationsState copyWith({
    AdminNotificationsStatus? status,
    String? message,
    bool clearMessage = false,
  }) =>
      AdminNotificationsState(
        status: status ?? this.status,
        message: clearMessage ? null : (message ?? this.message),
      );

  @override
  List<Object?> get props => [status, message];
}
