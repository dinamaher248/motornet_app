import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:motorent/features/admin_dashboard/domain/entities/admin_entities.dart';
import 'package:motorent/features/admin_dashboard/domain/repositories/admin_repository.dart';

part 'admin_users_event.dart';
part 'admin_users_state.dart';

class AdminUsersBloc extends Bloc<AdminUsersEvent, AdminUsersState> {
  final AdminRepository repository;

  AdminUsersBloc({required this.repository}) : super(const AdminUsersState()) {
    on<FetchAdminUsersEvent>(_onFetch);
    on<ToggleAdminUserEvent>(_onToggle);
    on<DeleteAdminUserEvent>(_onDelete);
    on<ReviewAdminUserEvent>(_onReview);
    on<ApproveAdminUserDocumentsEvent>(_onApproveDocuments);
  }

  Future<void> _onFetch(
    FetchAdminUsersEvent event,
    Emitter<AdminUsersState> emit,
  ) async {
    emit(state.copyWith(
      status: AdminUsersStatus.loading,
      selectedRole: event.role,
      selectedDriverSegment:
          event.driverSegment ?? state.selectedDriverSegment,
      searchQuery: event.search ?? state.searchQuery,
      clearMessage: true,
    ));
    final search = (event.search ?? state.searchQuery).trim();
    final result = await repository.fetchUsers(
      role: event.role,
      driverSegment: event.role == AdminUserRole.driver
          ? (event.driverSegment ?? state.selectedDriverSegment)
          : null,
      search: search.isEmpty ? null : search,
    );
    result.fold(
      (f) => emit(state.copyWith(
        status: AdminUsersStatus.failure,
        message: f.message,
      )),
      (users) => emit(state.copyWith(
        status: AdminUsersStatus.loaded,
        users: users,
      )),
    );
  }

  Future<void> _onToggle(
    ToggleAdminUserEvent event,
    Emitter<AdminUsersState> emit,
  ) async {
    emit(state.copyWith(actingUserId: event.userId, clearMessage: true));
    final result = await repository.toggleUser(event.userId);
    result.fold(
      (f) => emit(state.copyWith(
        clearActing: true,
        message: f.message,
        status: AdminUsersStatus.failure,
      )),
      (user) {
        final list =
            state.users.map((u) => u.id == user.id ? user : u).toList();
        emit(state.copyWith(
          clearActing: true,
          users: list,
          status: AdminUsersStatus.loaded,
          message: user.isActive ? 'تم تفعيل المستخدم' : 'تم إيقاف المستخدم مؤقتاً',
        ));
      },
    );
  }

  Future<void> _onDelete(
    DeleteAdminUserEvent event,
    Emitter<AdminUsersState> emit,
  ) async {
    emit(state.copyWith(actingUserId: event.userId, clearMessage: true));
    final result = await repository.deleteUser(event.userId);
    result.fold(
      (f) => emit(state.copyWith(
        clearActing: true,
        message: f.message,
        status: AdminUsersStatus.failure,
      )),
      (_) {
        final list = state.users.where((u) => u.id != event.userId).toList();
        emit(state.copyWith(
          clearActing: true,
          users: list,
          status: AdminUsersStatus.loaded,
          message: 'تم حذف الحساب نهائياً',
        ));
      },
    );
  }

  Future<void> _onReview(
    ReviewAdminUserEvent event,
    Emitter<AdminUsersState> emit,
  ) async {
    emit(state.copyWith(actingUserId: event.userId, clearMessage: true));
    final result = await repository.reviewUser(event.userId);
    result.fold(
      (f) => emit(state.copyWith(
        clearActing: true,
        message: f.message,
        status: AdminUsersStatus.failure,
      )),
      (user) => emit(state.copyWith(
        clearActing: true,
        reviewedUser: user,
        status: AdminUsersStatus.loaded,
      )),
    );
  }

  Future<void> _onApproveDocuments(
    ApproveAdminUserDocumentsEvent event,
    Emitter<AdminUsersState> emit,
  ) async {
    emit(state.copyWith(actingUserId: event.userId, clearMessage: true));
    final result = await repository.approveUserDocuments(event.userId);
    result.fold(
      (f) => emit(state.copyWith(
        clearActing: true,
        message: f.message,
        status: AdminUsersStatus.failure,
      )),
      (user) {
        final list = state.selectedDriverSegment == AdminDriverSegment.newUsers
            ? state.users.where((u) => u.id != user.id).toList()
            : state.users.map((u) => u.id == user.id ? user : u).toList();
        emit(state.copyWith(
          clearActing: true,
          users: list,
          reviewedUser: user,
          status: AdminUsersStatus.loaded,
          message: 'تم اعتماد المستندات وتفعيل الحساب',
        ));
      },
    );
  }
}
