import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:motorent/features/admin_dashboard/domain/entities/admin_entities.dart';
import 'package:motorent/features/admin_dashboard/domain/repositories/admin_repository.dart';

part 'admin_moderators_event.dart';
part 'admin_moderators_state.dart';

class AdminModeratorsBloc
    extends Bloc<AdminModeratorsEvent, AdminModeratorsState> {
  final AdminRepository repository;

  AdminModeratorsBloc({required this.repository})
      : super(const AdminModeratorsState()) {
    on<FetchAdminModeratorsEvent>(_onFetch);
    on<CreateAdminModeratorEvent>(_onCreate);
    on<UpdateAdminModeratorEvent>(_onUpdate);
    on<ToggleAdminModeratorEvent>(_onToggle);
    on<DeleteAdminModeratorEvent>(_onDelete);
  }

  Future<void> _onFetch(
    FetchAdminModeratorsEvent event,
    Emitter<AdminModeratorsState> emit,
  ) async {
    emit(state.copyWith(
        status: AdminModeratorsStatus.loading, clearMessage: true));
    final result = await repository.fetchModerators();
    result.fold(
      (f) => emit(state.copyWith(
          status: AdminModeratorsStatus.failure, message: f.message)),
      (list) => emit(state.copyWith(
          status: AdminModeratorsStatus.loaded, moderators: list)),
    );
  }

  Future<void> _onCreate(
    CreateAdminModeratorEvent event,
    Emitter<AdminModeratorsState> emit,
  ) async {
    emit(state.copyWith(busy: true, clearMessage: true));
    final result = await repository.createModerator(
      name: event.name,
      phone: event.phone,
      email: event.email,
      password: event.password,
      permissions: event.permissions,
    );
    result.fold(
      (f) => emit(state.copyWith(busy: false, message: f.message)),
      (m) => emit(state.copyWith(
        busy: false,
        moderators: [...state.moderators, m],
        message: 'تمت إضافة المشرف',
      )),
    );
  }

  Future<void> _onUpdate(
    UpdateAdminModeratorEvent event,
    Emitter<AdminModeratorsState> emit,
  ) async {
    emit(state.copyWith(busy: true, clearMessage: true));
    final result = await repository.updateModerator(event.moderator);
    result.fold(
      (f) => emit(state.copyWith(busy: false, message: f.message)),
      (m) {
        final list =
            state.moderators.map((e) => e.id == m.id ? m : e).toList();
        emit(state.copyWith(
            busy: false, moderators: list, message: 'تم تعديل المشرف'));
      },
    );
  }

  Future<void> _onToggle(
    ToggleAdminModeratorEvent event,
    Emitter<AdminModeratorsState> emit,
  ) async {
    emit(state.copyWith(busy: true, clearMessage: true));
    final result = await repository.toggleModerator(event.id);
    result.fold(
      (f) => emit(state.copyWith(busy: false, message: f.message)),
      (m) {
        final list =
            state.moderators.map((e) => e.id == m.id ? m : e).toList();
        emit(state.copyWith(
          busy: false,
          moderators: list,
          message: m.isActive ? 'تم تفعيل المشرف' : 'تم إيقاف المشرف',
        ));
      },
    );
  }

  Future<void> _onDelete(
    DeleteAdminModeratorEvent event,
    Emitter<AdminModeratorsState> emit,
  ) async {
    emit(state.copyWith(busy: true, clearMessage: true));
    final result = await repository.deleteModerator(event.id);
    result.fold(
      (f) => emit(state.copyWith(busy: false, message: f.message)),
      (_) => emit(state.copyWith(
        busy: false,
        moderators: state.moderators.where((e) => e.id != event.id).toList(),
        message: 'تم حذف المشرف',
      )),
    );
  }
}
