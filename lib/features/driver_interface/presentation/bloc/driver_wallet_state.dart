part of 'driver_wallet_bloc.dart';

enum DriverWalletStatus {
  initial,
  loading,
  loaded,
  submitting,
  settlementSuccess,
  failure,
}

class DriverWalletState extends Equatable {
  final DriverWalletStatus status;
  final DriverWallet? wallet;
  final String? message;

  const DriverWalletState({
    this.status = DriverWalletStatus.initial,
    this.wallet,
    this.message,
  });

  DriverWalletState copyWith({
    DriverWalletStatus? status,
    DriverWallet? wallet,
    String? message,
    bool clearMessage = false,
  }) {
    return DriverWalletState(
      status: status ?? this.status,
      wallet: wallet ?? this.wallet,
      message: clearMessage ? null : (message ?? this.message),
    );
  }

  @override
  List<Object?> get props => [status, wallet, message];
}
