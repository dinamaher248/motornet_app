part of 'admin_plans_bloc.dart';

enum AdminPlansStatus { initial, loading, loaded, failure }

class AdminPlansState extends Equatable {
  final AdminPlansStatus status;
  final AdminPlansSettings settings;
  final List<AdminPlan> plans;
  final bool settingsDirty;
  final bool savingSettings;
  final bool busy;
  final String? message;

  const AdminPlansState({
    this.status = AdminPlansStatus.initial,
    this.settings = const AdminPlansSettings(),
    this.plans = const [],
    this.settingsDirty = false,
    this.savingSettings = false,
    this.busy = false,
    this.message,
  });

  AdminPlansState copyWith({
    AdminPlansStatus? status,
    AdminPlansSettings? settings,
    List<AdminPlan>? plans,
    bool? settingsDirty,
    bool? savingSettings,
    bool? busy,
    String? message,
    bool clearMessage = false,
  }) =>
      AdminPlansState(
        status: status ?? this.status,
        settings: settings ?? this.settings,
        plans: plans ?? this.plans,
        settingsDirty: settingsDirty ?? this.settingsDirty,
        savingSettings: savingSettings ?? this.savingSettings,
        busy: busy ?? this.busy,
        message: clearMessage ? null : (message ?? this.message),
      );

  @override
  List<Object?> get props => [
        status,
        settings,
        plans,
        settingsDirty,
        savingSettings,
        busy,
        message,
      ];
}
