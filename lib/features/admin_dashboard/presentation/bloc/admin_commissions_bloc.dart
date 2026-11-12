import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:motorent/features/admin_dashboard/domain/entities/admin_entities.dart';
import 'package:motorent/features/admin_dashboard/domain/repositories/admin_repository.dart';

part 'admin_commissions_event.dart';
part 'admin_commissions_state.dart';

class AdminCommissionsBloc
    extends Bloc<AdminCommissionsEvent, AdminCommissionsState> {
  final AdminRepository repository;

  AdminCommissionsBloc({required this.repository})
      : super(const AdminCommissionsState()) {
    on<LoadAdminCommissionsEvent>(_onLoad);
    on<UpdateCommissionEnabledEvent>(_onToggleEnabled);
    on<UpdateCommissionFieldsEvent>(_onUpdateFields);
    on<UpdateVendorOrdersCommissionEnabledEvent>(_onToggleVendorOrdersCommission);
    on<UpdateVendorOrdersFixedFeeEnabledEvent>(_onToggleVendorOrdersFixedFee);
    on<SaveCommissionSettingsEvent>(_onSave);
    on<HandleSettlementEvent>(_onHandleSettlement);
  }

  Future<void> _onLoad(
    LoadAdminCommissionsEvent event,
    Emitter<AdminCommissionsState> emit,
  ) async {
    emit(state.copyWith(
        status: AdminCommissionsStatus.loading, clearMessage: true));
    final settingsResult = await repository.fetchCommissionSettings();
    final settlementsResult = await repository.fetchSettlements();

    String? err;
    AdminCommissionSettings? settings;
    List<AdminSettlementRequest>? settlements;

    settingsResult.fold((f) => err = f.message, (s) => settings = s);
    settlementsResult.fold((f) => err ??= f.message, (s) => settlements = s);

    if (err != null && settings == null) {
      emit(state.copyWith(
          status: AdminCommissionsStatus.failure, message: err));
      return;
    }
    emit(state.copyWith(
      status: AdminCommissionsStatus.loaded,
      settings: settings ?? state.settings,
      settlements: settlements ?? state.settlements,
      message: err,
    ));
  }

  void _onToggleEnabled(
    UpdateCommissionEnabledEvent event,
    Emitter<AdminCommissionsState> emit,
  ) {
    emit(state.copyWith(
      settings: state.settings.copyWith(commissionEnabled: event.enabled),
      dirty: true,
    ));
  }

  void _onUpdateFields(
    UpdateCommissionFieldsEvent event,
    Emitter<AdminCommissionsState> emit,
  ) {
    emit(state.copyWith(
      settings: state.settings.copyWith(
        driverCommissionPercent: event.driverPercent,
        vendorCommissionPercent: event.vendorPercent,
        debtLimit: event.debtLimit,
        vendorOrdersCommissionEnabled: event.vendorOrdersCommissionEnabled,
        vendorOrdersCommissionPercent: event.vendorOrdersCommissionPercent,
        vendorOrdersFixedFeeEnabled: event.vendorOrdersFixedFeeEnabled,
        vendorOrdersFixedFeeAmount: event.vendorOrdersFixedFeeAmount,
      ),
      dirty: true,
    ));
  }

  void _onToggleVendorOrdersCommission(
    UpdateVendorOrdersCommissionEnabledEvent event,
    Emitter<AdminCommissionsState> emit,
  ) {
    emit(state.copyWith(
      settings: state.settings.copyWith(
        vendorOrdersCommissionEnabled: event.enabled,
      ),
      dirty: true,
    ));
  }

  void _onToggleVendorOrdersFixedFee(
    UpdateVendorOrdersFixedFeeEnabledEvent event,
    Emitter<AdminCommissionsState> emit,
  ) {
    emit(state.copyWith(
      settings: state.settings.copyWith(
        vendorOrdersFixedFeeEnabled: event.enabled,
      ),
      dirty: true,
    ));
  }

  Future<void> _onSave(
    SaveCommissionSettingsEvent event,
    Emitter<AdminCommissionsState> emit,
  ) async {
    emit(state.copyWith(saving: true, clearMessage: true));
    final result = await repository.saveCommissionSettings(state.settings);
    result.fold(
      (f) => emit(state.copyWith(saving: false, message: f.message)),
      (s) => emit(state.copyWith(
        saving: false,
        dirty: false,
        settings: s,
        message: 'تم حفظ إعدادات العمولة',
      )),
    );
  }

  Future<void> _onHandleSettlement(
    HandleSettlementEvent event,
    Emitter<AdminCommissionsState> emit,
  ) async {
    emit(state.copyWith(actingSettlementId: event.id, clearMessage: true));
    final result = await repository.handleSettlement(
      id: event.id,
      action: event.action,
    );
    await result.fold(
      (f) async =>
          emit(state.copyWith(clearActing: true, message: f.message)),
      (item) async {
        final reloadActions = {
          'mark_paid',
          'suspend_all',
          'activate_all',
          'notify_all',
          'approve',
          'approve_receipt',
        };
        if (reloadActions.contains(event.action)) {
          final settlementsResult = await repository.fetchSettlements();
          final list = settlementsResult.fold(
            (_) => state.settlements
                .where((e) =>
                    event.action != 'mark_paid' || e.id != event.id)
                .toList(),
            (s) => s,
          );
          final messages = {
            'mark_paid': 'تم سداد المديونية وتفعيل الحساب',
            'suspend_all': 'تم إيقاف كل اللي عليهم مديونية',
            'activate_all': 'تم تشغيل كل اللي عليهم مديونية',
            'notify_all': 'تم إرسال الإشعار للمديونين',
            'approve': 'تم قبول الإيصال',
            'approve_receipt': 'تم قبول الإيصال',
          };
          emit(state.copyWith(
            clearActing: true,
            settlements: list,
            message: messages[event.action] ?? 'تم',
          ));
          return;
        }
        final list = state.settlements
            .map((e) => e.id == item.id ? item : e)
            .toList();
        emit(state.copyWith(
          clearActing: true,
          settlements: list,
          message: event.action == 'toggle'
              ? (item.isSuspended ? 'تم إيقاف الحساب' : 'تم تشغيل الحساب')
              : 'تم',
        ));
      },
    );
  }
}
