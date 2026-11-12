import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:motorent/features/admin_dashboard/domain/entities/admin_entities.dart';
import 'package:motorent/features/admin_dashboard/domain/repositories/admin_repository.dart';

part 'admin_notifications_event.dart';
part 'admin_notifications_state.dart';

class AdminNotificationsBloc
    extends Bloc<AdminNotificationsEvent, AdminNotificationsState> {
  final AdminRepository repository;

  AdminNotificationsBloc({required this.repository})
      : super(const AdminNotificationsState()) {
    on<SendAdminPushEvent>(_onSend);
  }

  Future<void> _onSend(
    SendAdminPushEvent event,
    Emitter<AdminNotificationsState> emit,
  ) async {
    emit(state.copyWith(
        status: AdminNotificationsStatus.sending, clearMessage: true));
    final result = await repository.sendNotification(event.params);
    result.fold(
      (f) => emit(state.copyWith(
        status: AdminNotificationsStatus.failure,
        message: f.message,
      )),
      (_) => emit(state.copyWith(
        status: AdminNotificationsStatus.success,
        message: 'تم إرسال الإشعار بنجاح',
      )),
    );
  }
}
