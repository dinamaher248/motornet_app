import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:motorent/features/admin_dashboard/domain/entities/admin_entities.dart';
import 'package:motorent/features/admin_dashboard/domain/repositories/admin_repository.dart';

part 'admin_plans_event.dart';
part 'admin_plans_state.dart';

class AdminPlansBloc extends Bloc<AdminPlansEvent, AdminPlansState> {
  final AdminRepository repository;

  AdminPlansBloc({required this.repository}) : super(const AdminPlansState()) {
    on<LoadAdminPlansEvent>(_onLoad);
    on<UpdatePlansMasterSwitchesEvent>(_onSwitches);
    on<SavePlansSettingsEvent>(_onSaveSettings);
    on<CreateAdminPlanEvent>(_onCreate);
    on<UpdateAdminPlanEvent>(_onUpdate);
    on<DeleteAdminPlanEvent>(_onDelete);
  }

  Future<void> _onLoad(
    LoadAdminPlansEvent event,
    Emitter<AdminPlansState> emit,
  ) async {
    emit(state.copyWith(status: AdminPlansStatus.loading, clearMessage: true));
    final settingsResult = await repository.fetchPlansSettings();
    final plansResult = await repository.fetchPlans();

    String? err;
    AdminPlansSettings? settings;
    List<AdminPlan>? plans;

    settingsResult.fold((f) => err = f.message, (s) => settings = s);
    plansResult.fold((f) => err ??= f.message, (p) => plans = p);

    if (err != null && settings == null && plans == null) {
      emit(state.copyWith(status: AdminPlansStatus.failure, message: err));
      return;
    }
    emit(state.copyWith(
      status: AdminPlansStatus.loaded,
      settings: settings ?? state.settings,
      plans: plans ?? state.plans,
      message: err,
    ));
  }

  void _onSwitches(
    UpdatePlansMasterSwitchesEvent event,
    Emitter<AdminPlansState> emit,
  ) {
    emit(state.copyWith(
      settings: state.settings.copyWith(
        driversPlansEnabled: event.driversEnabled,
        vendorsPlansEnabled: event.vendorsEnabled,
      ),
      settingsDirty: true,
    ));
  }

  Future<void> _onSaveSettings(
    SavePlansSettingsEvent event,
    Emitter<AdminPlansState> emit,
  ) async {
    emit(state.copyWith(savingSettings: true, clearMessage: true));
    final result = await repository.savePlansSettings(state.settings);
    result.fold(
      (f) => emit(state.copyWith(savingSettings: false, message: f.message)),
      (s) => emit(state.copyWith(
        savingSettings: false,
        settingsDirty: false,
        settings: s,
        message: 'تم حفظ إعدادات الخطط',
      )),
    );
  }

  Future<void> _onCreate(
    CreateAdminPlanEvent event,
    Emitter<AdminPlansState> emit,
  ) async {
    emit(state.copyWith(busy: true, clearMessage: true));
    final result = await repository.createPlan(event.plan);
    result.fold(
      (f) => emit(state.copyWith(busy: false, message: f.message)),
      (plan) => emit(state.copyWith(
        busy: false,
        plans: [...state.plans, plan],
        message: 'تمت إضافة الخطة',
      )),
    );
  }

  Future<void> _onUpdate(
    UpdateAdminPlanEvent event,
    Emitter<AdminPlansState> emit,
  ) async {
    emit(state.copyWith(busy: true, clearMessage: true));
    final result = await repository.updatePlan(event.plan);
    result.fold(
      (f) => emit(state.copyWith(busy: false, message: f.message)),
      (plan) {
        final list =
            state.plans.map((e) => e.id == plan.id ? plan : e).toList();
        emit(state.copyWith(
            busy: false, plans: list, message: 'تم تعديل الخطة'));
      },
    );
  }

  Future<void> _onDelete(
    DeleteAdminPlanEvent event,
    Emitter<AdminPlansState> emit,
  ) async {
    emit(state.copyWith(busy: true, clearMessage: true));
    final result = await repository.deletePlan(event.id);
    result.fold(
      (f) => emit(state.copyWith(busy: false, message: f.message)),
      (_) => emit(state.copyWith(
        busy: false,
        plans: state.plans.where((e) => e.id != event.id).toList(),
        message: 'تم حذف الخطة',
      )),
    );
  }
}
