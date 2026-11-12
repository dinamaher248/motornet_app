part of 'service_bloc.dart';

abstract class ServiceState extends Equatable {
  const ServiceState();
  @override
  List<Object?> get props => [];
}

class ServiceInitial extends ServiceState {
  const ServiceInitial();
}

class ServiceLoading extends ServiceState {
  const ServiceLoading();
}

class StoresLoaded extends ServiceState {
  final String category;
  final List<Store> stores;

  const StoresLoaded({required this.category, required this.stores});

  @override
  List<Object?> get props => [category, stores];
}

class StoreDetailsLoaded extends ServiceState {
  final Store store;

  const StoreDetailsLoaded(this.store);

  @override
  List<Object?> get props => [store];
}

class OrderSubmitting extends ServiceState {
  final Store? store;

  const OrderSubmitting({this.store});

  @override
  List<Object?> get props => [store];
}

class OrderSubmitSuccess extends ServiceState {
  final ServiceOrder order;

  const OrderSubmitSuccess(this.order);

  @override
  List<Object?> get props => [order];
}

class OrderSubmitError extends ServiceState {
  final String message;
  final Store? store;

  const OrderSubmitError(this.message, {this.store});

  @override
  List<Object?> get props => [message, store];
}

class ServiceError extends ServiceState {
  final String message;

  const ServiceError(this.message);

  @override
  List<Object?> get props => [message];
}
