part of 'service_bloc.dart';

abstract class ServiceEvent extends Equatable {
  const ServiceEvent();
  @override
  List<Object?> get props => [];
}

class FetchStoresEvent extends ServiceEvent {
  final String category;
  final double? lat;
  final double? lng;
  final String? listingKind;

  const FetchStoresEvent(
    this.category, {
    this.lat,
    this.lng,
    this.listingKind,
  });

  @override
  List<Object?> get props => [category, lat, lng, listingKind];
}

class FetchStoreDetailsEvent extends ServiceEvent {
  final int storeId;
  final double? lat;
  final double? lng;

  const FetchStoreDetailsEvent(this.storeId, {this.lat, this.lng});

  @override
  List<Object?> get props => [storeId, lat, lng];
}

class SubmitServiceOrderEvent extends ServiceEvent {
  final CheckoutParams params;

  const SubmitServiceOrderEvent(this.params);

  @override
  List<Object?> get props => [params];
}
