part of 'admin_products_bloc.dart';

enum AdminProductsStatus { initial, loading, loaded, failure }

class AdminProductsState extends Equatable {
  final AdminProductsStatus status;
  final List<AdminProduct> products;
  final int? vendorId;
  final int? actingId;
  final String? message;

  const AdminProductsState({
    this.status = AdminProductsStatus.initial,
    this.products = const [],
    this.vendorId,
    this.actingId,
    this.message,
  });

  AdminProductsState copyWith({
    AdminProductsStatus? status,
    List<AdminProduct>? products,
    int? vendorId,
    int? actingId,
    String? message,
    bool clearMessage = false,
    bool clearActing = false,
  }) =>
      AdminProductsState(
        status: status ?? this.status,
        products: products ?? this.products,
        vendorId: vendorId ?? this.vendorId,
        actingId: clearActing ? null : (actingId ?? this.actingId),
        message: clearMessage ? null : (message ?? this.message),
      );

  @override
  List<Object?> get props => [status, products, vendorId, actingId, message];
}
