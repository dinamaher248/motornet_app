part of 'vendor_wallet_bloc.dart';

enum VendorWalletStatus {
  initial,
  loading,
  loaded,
  submitting,
  settlementSuccess,
  failure,
}

class VendorWalletState extends Equatable {
  final VendorWalletStatus status;
  final VendorWallet? wallet;
  final String? message;

  const VendorWalletState({
    this.status = VendorWalletStatus.initial,
    this.wallet,
    this.message,
  });

  VendorWalletState copyWith({
    VendorWalletStatus? status,
    VendorWallet? wallet,
    String? message,
    bool clearMessage = false,
  }) {
    return VendorWalletState(
      status: status ?? this.status,
      wallet: wallet ?? this.wallet,
      message: clearMessage ? null : (message ?? this.message),
    );
  }

  @override
  List<Object?> get props => [status, wallet, message];
}
