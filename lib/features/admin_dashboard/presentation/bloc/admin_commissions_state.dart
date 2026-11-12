part of 'admin_commissions_bloc.dart';

enum AdminCommissionsStatus { initial, loading, loaded, failure }

class AdminCommissionsState extends Equatable {
  final AdminCommissionsStatus status;
  final AdminCommissionSettings settings;
  final List<AdminSettlementRequest> settlements;
  final bool dirty;
  final bool saving;
  final int? actingSettlementId;
  final String? message;

  const AdminCommissionsState({
    this.status = AdminCommissionsStatus.initial,
    this.settings = const AdminCommissionSettings(),
    this.settlements = const [],
    this.dirty = false,
    this.saving = false,
    this.actingSettlementId,
    this.message,
  });

  AdminCommissionsState copyWith({
    AdminCommissionsStatus? status,
    AdminCommissionSettings? settings,
    List<AdminSettlementRequest>? settlements,
    bool? dirty,
    bool? saving,
    int? actingSettlementId,
    String? message,
    bool clearMessage = false,
    bool clearActing = false,
  }) =>
      AdminCommissionsState(
        status: status ?? this.status,
        settings: settings ?? this.settings,
        settlements: settlements ?? this.settlements,
        dirty: dirty ?? this.dirty,
        saving: saving ?? this.saving,
        actingSettlementId: clearActing
            ? null
            : (actingSettlementId ?? this.actingSettlementId),
        message: clearMessage ? null : (message ?? this.message),
      );

  @override
  List<Object?> get props => [
        status,
        settings,
        settlements,
        dirty,
        saving,
        actingSettlementId,
        message,
      ];
}
