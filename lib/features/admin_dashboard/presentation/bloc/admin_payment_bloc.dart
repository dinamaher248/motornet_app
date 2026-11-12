import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:motorent/features/admin_dashboard/domain/entities/admin_entities.dart';
import 'package:motorent/features/admin_dashboard/domain/repositories/admin_repository.dart';

part 'admin_payment_event.dart';
part 'admin_payment_state.dart';

class AdminPaymentBloc extends Bloc<AdminPaymentEvent, AdminPaymentState> {
  final AdminRepository repository;

  AdminPaymentBloc({required this.repository})
      : super(const AdminPaymentState()) {
    on<LoadAdminPaymentEvent>(_onLoad);
    on<UpdatePaymentDraftEvent>(_onDraft);
    on<SaveAdminPaymentEvent>(_onSave);
  }

  Future<void> _onLoad(
    LoadAdminPaymentEvent event,
    Emitter<AdminPaymentState> emit,
  ) async {
    emit(state.copyWith(
        status: AdminPaymentStatus.loading, clearMessage: true));
    final result = await repository.fetchPaymentSettings();
    result.fold(
      (f) => emit(state.copyWith(
          status: AdminPaymentStatus.failure, message: f.message)),
      (s) => emit(state.copyWith(
          status: AdminPaymentStatus.loaded, settings: s, dirty: false)),
    );
  }

  void _onDraft(
    UpdatePaymentDraftEvent event,
    Emitter<AdminPaymentState> emit,
  ) {
    emit(state.copyWith(
      settings: state.settings.copyWith(
        vodafoneCashNumber: event.vodafoneCashNumber,
        instapayHandle: event.instapayHandle,
        vodafoneEnabled: event.vodafoneEnabled,
        instapayEnabled: event.instapayEnabled,
        cashEnabled: event.cashEnabled,
      ),
      dirty: true,
    ));
  }

  Future<void> _onSave(
    SaveAdminPaymentEvent event,
    Emitter<AdminPaymentState> emit,
  ) async {
    emit(state.copyWith(saving: true, clearMessage: true));
    final result = await repository.savePaymentSettings(state.settings);
    result.fold(
      (f) => emit(state.copyWith(saving: false, message: f.message)),
      (s) => emit(state.copyWith(
        saving: false,
        dirty: false,
        settings: s,
        message: 'تم حفظ طرق الدفع',
      )),
    );
  }
}
