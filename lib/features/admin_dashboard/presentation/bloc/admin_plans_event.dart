part of 'admin_plans_bloc.dart';

abstract class AdminPlansEvent extends Equatable {
  const AdminPlansEvent();
  @override
  List<Object?> get props => [];
}

class LoadAdminPlansEvent extends AdminPlansEvent {
  const LoadAdminPlansEvent();
}

class UpdatePlansMasterSwitchesEvent extends AdminPlansEvent {
  final bool? driversEnabled;
  final bool? vendorsEnabled;
  const UpdatePlansMasterSwitchesEvent({
    this.driversEnabled,
    this.vendorsEnabled,
  });
  @override
  List<Object?> get props => [driversEnabled, vendorsEnabled];
}

class SavePlansSettingsEvent extends AdminPlansEvent {
  const SavePlansSettingsEvent();
}

class CreateAdminPlanEvent extends AdminPlansEvent {
  final AdminPlan plan;
  const CreateAdminPlanEvent(this.plan);
  @override
  List<Object?> get props => [plan];
}

class UpdateAdminPlanEvent extends AdminPlansEvent {
  final AdminPlan plan;
  const UpdateAdminPlanEvent(this.plan);
  @override
  List<Object?> get props => [plan];
}

class DeleteAdminPlanEvent extends AdminPlansEvent {
  final int id;
  const DeleteAdminPlanEvent(this.id);
  @override
  List<Object?> get props => [id];
}
