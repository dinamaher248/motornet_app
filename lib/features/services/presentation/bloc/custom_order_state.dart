part of 'custom_order_bloc.dart';

enum CustomOrderStatus {
  initial,
  submitting,
  submitSuccess,
  responding,
  respondSuccess,
  failure,
}

class CustomOrderState extends Equatable {
  final CustomOrderStatus status;
  final CustomOrder? order;
  final String? message;

  const CustomOrderState({
    this.status = CustomOrderStatus.initial,
    this.order,
    this.message,
  });

  bool get isBusy =>
      status == CustomOrderStatus.submitting ||
      status == CustomOrderStatus.responding;

  CustomOrderState copyWith({
    CustomOrderStatus? status,
    CustomOrder? order,
    String? message,
    bool clearMessage = false,
    bool clearOrder = false,
  }) {
    return CustomOrderState(
      status: status ?? this.status,
      order: clearOrder ? null : (order ?? this.order),
      message: clearMessage ? null : (message ?? this.message),
    );
  }

  @override
  List<Object?> get props => [status, order, message];
}
