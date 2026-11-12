part of 'vendor_store_bloc.dart';

enum VendorStoreStatus { initial, loading, loaded, saving, saved, failure }

class VendorStoreState extends Equatable {
  final VendorStoreStatus status;
  final VendorStore? store;
  final String? message;

  const VendorStoreState({
    this.status = VendorStoreStatus.initial,
    this.store,
    this.message,
  });

  VendorStoreState copyWith({
    VendorStoreStatus? status,
    VendorStore? store,
    String? message,
    bool clearMessage = false,
  }) {
    return VendorStoreState(
      status: status ?? this.status,
      store: store ?? this.store,
      message: clearMessage ? null : (message ?? this.message),
    );
  }

  @override
  List<Object?> get props => [status, store, message];
}
