part of 'custom_order_bloc.dart';

abstract class CustomOrderEvent extends Equatable {
  const CustomOrderEvent();

  @override
  List<Object?> get props => [];
}

class SubmitCustomOrderEvent extends CustomOrderEvent {
  final SubmitCustomOrderParams params;

  const SubmitCustomOrderEvent(this.params);

  @override
  List<Object?> get props => [params];
}

class RespondToVendorOfferEvent extends CustomOrderEvent {
  final int orderId;
  final String action; // 'accept' | 'reject'

  const RespondToVendorOfferEvent({
    required this.orderId,
    required this.action,
  });

  @override
  List<Object?> get props => [orderId, action];
}
