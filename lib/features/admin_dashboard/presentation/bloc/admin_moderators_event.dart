part of 'admin_moderators_bloc.dart';

abstract class AdminModeratorsEvent extends Equatable {
  const AdminModeratorsEvent();
  @override
  List<Object?> get props => [];
}

class FetchAdminModeratorsEvent extends AdminModeratorsEvent {
  const FetchAdminModeratorsEvent();
}

class CreateAdminModeratorEvent extends AdminModeratorsEvent {
  final String name;
  final String phone;
  final String email;
  final String password;
  final List<String> permissions;
  const CreateAdminModeratorEvent({
    required this.name,
    required this.phone,
    this.email = '',
    this.password = '',
    this.permissions = const [],
  });
  @override
  List<Object?> get props => [name, phone, email, password, permissions];
}

class UpdateAdminModeratorEvent extends AdminModeratorsEvent {
  final AdminModerator moderator;
  const UpdateAdminModeratorEvent(this.moderator);
  @override
  List<Object?> get props => [moderator];
}

class ToggleAdminModeratorEvent extends AdminModeratorsEvent {
  final int id;
  const ToggleAdminModeratorEvent(this.id);
  @override
  List<Object?> get props => [id];
}

class DeleteAdminModeratorEvent extends AdminModeratorsEvent {
  final int id;
  const DeleteAdminModeratorEvent(this.id);
  @override
  List<Object?> get props => [id];
}
