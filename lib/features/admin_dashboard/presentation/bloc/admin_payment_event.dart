part of 'admin_payment_bloc.dart';

abstract class AdminPaymentEvent extends Equatable {
  const AdminPaymentEvent();
  @override
  List<Object?> get props => [];
}

class LoadAdminPaymentEvent extends AdminPaymentEvent {
  const LoadAdminPaymentEvent();
}

class UpdatePaymentDraftEvent extends AdminPaymentEvent {
  final String? vodafoneCashNumber;
  final String? instapayHandle;
  final bool? vodafoneEnabled;
  final bool? instapayEnabled;
  final bool? cashEnabled;

  const UpdatePaymentDraftEvent({
    this.vodafoneCashNumber,
    this.instapayHandle,
    this.vodafoneEnabled,
    this.instapayEnabled,
    this.cashEnabled,
  });

  @override
  List<Object?> get props => [
        vodafoneCashNumber,
        instapayHandle,
        vodafoneEnabled,
        instapayEnabled,
        cashEnabled,
      ];
}

class SaveAdminPaymentEvent extends AdminPaymentEvent {
  const SaveAdminPaymentEvent();
}
