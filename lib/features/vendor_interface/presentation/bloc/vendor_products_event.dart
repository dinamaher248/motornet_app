part of 'vendor_products_bloc.dart';

abstract class VendorProductsEvent extends Equatable {
  const VendorProductsEvent();
  @override
  List<Object?> get props => [];
}

class FetchVendorProductsEvent extends VendorProductsEvent {
  const FetchVendorProductsEvent();
}

class ToggleVendorProductEvent extends VendorProductsEvent {
  final int productId;
  const ToggleVendorProductEvent(this.productId);
  @override
  List<Object?> get props => [productId];
}

class CreateVendorProductEvent extends VendorProductsEvent {
  final CreateVendorProductParams params;
  const CreateVendorProductEvent(this.params);
  @override
  List<Object?> get props => [params];
}

class UpdateVendorProductEvent extends VendorProductsEvent {
  final UpdateVendorProductParams params;
  const UpdateVendorProductEvent(this.params);
  @override
  List<Object?> get props => [params];
}

class DeleteVendorProductEvent extends VendorProductsEvent {
  final int productId;
  const DeleteVendorProductEvent(this.productId);
  @override
  List<Object?> get props => [productId];
}
