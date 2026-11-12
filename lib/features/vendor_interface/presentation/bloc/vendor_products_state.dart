part of 'vendor_products_bloc.dart';

enum VendorProductsStatus {
  initial,
  loading,
  loaded,
  creating,
  created,
  updating,
  updated,
  deleting,
  failure,
}

class VendorProductsState extends Equatable {
  final VendorProductsStatus status;
  final List<VendorProduct> products;
  final String? message;

  const VendorProductsState({
    this.status = VendorProductsStatus.initial,
    this.products = const [],
    this.message,
  });

  bool get canAddMore => products.length < 10;

  VendorProductsState copyWith({
    VendorProductsStatus? status,
    List<VendorProduct>? products,
    String? message,
    bool clearMessage = false,
  }) {
    return VendorProductsState(
      status: status ?? this.status,
      products: products ?? this.products,
      message: clearMessage ? null : (message ?? this.message),
    );
  }

  @override
  List<Object?> get props => [status, products, message];
}
