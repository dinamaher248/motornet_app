part of 'vendor_wallet_bloc.dart';

abstract class VendorWalletEvent extends Equatable {
  const VendorWalletEvent();
  @override
  List<Object?> get props => [];
}

class FetchVendorWalletEvent extends VendorWalletEvent {
  const FetchVendorWalletEvent();
}

class UpdateVendorBillingModeEvent extends VendorWalletEvent {
  final String billingMode;

  const UpdateVendorBillingModeEvent(this.billingMode);

  @override
  List<Object?> get props => [billingMode];
}

class SubmitVendorSettlementEvent extends VendorWalletEvent {
  final File receipt;
  final double amount;

  const SubmitVendorSettlementEvent({
    required this.receipt,
    required this.amount,
  });

  @override
  List<Object?> get props => [receipt.path, amount];
}
