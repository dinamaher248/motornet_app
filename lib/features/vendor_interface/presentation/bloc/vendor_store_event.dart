part of 'vendor_store_bloc.dart';

abstract class VendorStoreEvent extends Equatable {
  const VendorStoreEvent();
  @override
  List<Object?> get props => [];
}

class FetchVendorStoreEvent extends VendorStoreEvent {
  const FetchVendorStoreEvent();
}

class SubmitVendorStoreEvent extends VendorStoreEvent {
  final UpdateVendorStoreParams params;
  const SubmitVendorStoreEvent(this.params);
  @override
  List<Object?> get props => [params];
}
