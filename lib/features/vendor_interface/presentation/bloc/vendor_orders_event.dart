part of 'vendor_orders_bloc.dart';

abstract class VendorOrdersEvent extends Equatable {
  const VendorOrdersEvent();
  @override
  List<Object?> get props => [];
}

class FetchVendorOrdersEvent extends VendorOrdersEvent {
  const FetchVendorOrdersEvent();
}

class HandleVendorOrderEvent extends VendorOrdersEvent {
  final int orderId;
  final String action;
  final String orderType;

  const HandleVendorOrderEvent({
    required this.orderId,
    required this.action,
    this.orderType = 'normal',
  });

  @override
  List<Object?> get props => [orderId, action, orderType];
}

class SendCustomOfferEvent extends VendorOrdersEvent {
  final SendCustomOfferParams params;

  const SendCustomOfferEvent(this.params);

  @override
  List<Object?> get props => [params];
}
