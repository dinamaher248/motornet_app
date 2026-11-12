part of 'admin_moderators_bloc.dart';

enum AdminModeratorsStatus { initial, loading, loaded, failure }

class AdminModeratorsState extends Equatable {
  final AdminModeratorsStatus status;
  final List<AdminModerator> moderators;
  final bool busy;
  final String? message;

  const AdminModeratorsState({
    this.status = AdminModeratorsStatus.initial,
    this.moderators = const [],
    this.busy = false,
    this.message,
  });

  AdminModeratorsState copyWith({
    AdminModeratorsStatus? status,
    List<AdminModerator>? moderators,
    bool? busy,
    String? message,
    bool clearMessage = false,
  }) =>
      AdminModeratorsState(
        status: status ?? this.status,
        moderators: moderators ?? this.moderators,
        busy: busy ?? this.busy,
        message: clearMessage ? null : (message ?? this.message),
      );

  @override
  List<Object?> get props => [status, moderators, busy, message];
}
