part of 'driver_wallet_bloc.dart';

abstract class DriverWalletEvent extends Equatable {
  const DriverWalletEvent();
  @override
  List<Object?> get props => [];
}

class FetchWalletStats extends DriverWalletEvent {
  const FetchWalletStats();
}

class UpdateDriverBillingModeEvent extends DriverWalletEvent {
  final String billingMode;

  const UpdateDriverBillingModeEvent(this.billingMode);

  @override
  List<Object?> get props => [billingMode];
}

class SubmitSettlementEvent extends DriverWalletEvent {
  final File receipt;
  final double amount;

  const SubmitSettlementEvent({
    required this.receipt,
    required this.amount,
  });

  @override
  List<Object?> get props => [receipt.path, amount];
}
