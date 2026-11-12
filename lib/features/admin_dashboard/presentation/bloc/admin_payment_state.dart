part of 'admin_payment_bloc.dart';

enum AdminPaymentStatus { initial, loading, loaded, failure }

class AdminPaymentState extends Equatable {
  final AdminPaymentStatus status;
  final AdminPaymentSettings settings;
  final bool dirty;
  final bool saving;
  final String? message;

  const AdminPaymentState({
    this.status = AdminPaymentStatus.initial,
    this.settings = const AdminPaymentSettings(),
    this.dirty = false,
    this.saving = false,
    this.message,
  });

  AdminPaymentState copyWith({
    AdminPaymentStatus? status,
    AdminPaymentSettings? settings,
    bool? dirty,
    bool? saving,
    String? message,
    bool clearMessage = false,
  }) =>
      AdminPaymentState(
        status: status ?? this.status,
        settings: settings ?? this.settings,
        dirty: dirty ?? this.dirty,
        saving: saving ?? this.saving,
        message: clearMessage ? null : (message ?? this.message),
      );

  @override
  List<Object?> get props => [status, settings, dirty, saving, message];
}
