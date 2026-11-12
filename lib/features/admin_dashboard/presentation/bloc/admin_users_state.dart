part of 'admin_users_bloc.dart';

enum AdminUsersStatus { initial, loading, loaded, failure }

class AdminUsersState extends Equatable {
  final AdminUsersStatus status;
  final AdminUserRole selectedRole;
  final AdminDriverSegment selectedDriverSegment;
  final String searchQuery;
  final List<AdminUser> users;
  final AdminUser? reviewedUser;
  final int? actingUserId;
  final String? message;

  const AdminUsersState({
    this.status = AdminUsersStatus.initial,
    this.selectedRole = AdminUserRole.client,
    this.selectedDriverSegment = AdminDriverSegment.currentUsers,
    this.searchQuery = '',
    this.users = const [],
    this.reviewedUser,
    this.actingUserId,
    this.message,
  });

  AdminUsersState copyWith({
    AdminUsersStatus? status,
    AdminUserRole? selectedRole,
    AdminDriverSegment? selectedDriverSegment,
    String? searchQuery,
    List<AdminUser>? users,
    AdminUser? reviewedUser,
    int? actingUserId,
    String? message,
    bool clearMessage = false,
    bool clearActing = false,
    bool clearReviewed = false,
  }) =>
      AdminUsersState(
        status: status ?? this.status,
        selectedRole: selectedRole ?? this.selectedRole,
        selectedDriverSegment:
            selectedDriverSegment ?? this.selectedDriverSegment,
        searchQuery: searchQuery ?? this.searchQuery,
        users: users ?? this.users,
        reviewedUser:
            clearReviewed ? null : (reviewedUser ?? this.reviewedUser),
        actingUserId:
            clearActing ? null : (actingUserId ?? this.actingUserId),
        message: clearMessage ? null : (message ?? this.message),
      );

  @override
  List<Object?> get props => [
        status,
        selectedRole,
        selectedDriverSegment,
        searchQuery,
        users,
        reviewedUser,
        actingUserId,
        message,
      ];
}
