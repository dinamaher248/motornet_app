part of 'vendor_orders_bloc.dart';

enum VendorOrdersStatus { initial, loading, loaded, failure }

class VendorOrdersState extends Equatable {
  final VendorOrdersStatus status;
  final List<VendorOrder> orders;
  final int? handlingOrderId;
  final String? message;

  const VendorOrdersState({
    this.status = VendorOrdersStatus.initial,
    this.orders = const [],
    this.handlingOrderId,
    this.message,
  });

  VendorOrdersState copyWith({
    VendorOrdersStatus? status,
    List<VendorOrder>? orders,
    int? handlingOrderId,
    String? message,
    bool clearMessage = false,
    bool clearHandling = false,
  }) {
    return VendorOrdersState(
      status: status ?? this.status,
      orders: orders ?? this.orders,
      handlingOrderId:
          clearHandling ? null : (handlingOrderId ?? this.handlingOrderId),
      message: clearMessage ? null : (message ?? this.message),
    );
  }

  @override
  List<Object?> get props => [status, orders, handlingOrderId, message];
}
