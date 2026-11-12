part of 'admin_users_bloc.dart';

abstract class AdminUsersEvent extends Equatable {
  const AdminUsersEvent();
  @override
  List<Object?> get props => [];
}

class FetchAdminUsersEvent extends AdminUsersEvent {
  final AdminUserRole role;
  final AdminDriverSegment? driverSegment;
  final String? search;
  const FetchAdminUsersEvent(
    this.role, {
    this.driverSegment,
    this.search,
  });
  @override
  List<Object?> get props => [role, driverSegment, search];
}

class ToggleAdminUserEvent extends AdminUsersEvent {
  final int userId;
  const ToggleAdminUserEvent(this.userId);
  @override
  List<Object?> get props => [userId];
}

class DeleteAdminUserEvent extends AdminUsersEvent {
  final int userId;
  const DeleteAdminUserEvent(this.userId);
  @override
  List<Object?> get props => [userId];
}

class ReviewAdminUserEvent extends AdminUsersEvent {
  final int userId;
  const ReviewAdminUserEvent(this.userId);
  @override
  List<Object?> get props => [userId];
}

class ApproveAdminUserDocumentsEvent extends AdminUsersEvent {
  final int userId;
  const ApproveAdminUserDocumentsEvent(this.userId);
  @override
  List<Object?> get props => [userId];
}
