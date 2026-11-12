part of 'trip_tracking_bloc.dart';

abstract class TripTrackingEvent extends Equatable {
  const TripTrackingEvent();

  @override
  List<Object?> get props => [];
}

class FetchMyTripsEvent extends TripTrackingEvent {
  const FetchMyTripsEvent();
}

class FetchTripDetailsEvent extends TripTrackingEvent {
  final int id;
  final bool silent;

  const FetchTripDetailsEvent(this.id, {this.silent = false});

  @override
  List<Object?> get props => [id, silent];
}

class AcceptTripOfferEvent extends TripTrackingEvent {
  final int offerId;

  const AcceptTripOfferEvent(this.offerId);

  @override
  List<Object?> get props => [offerId];
}

class CancelTripEvent extends TripTrackingEvent {
  final int id;

  const CancelTripEvent(this.id);

  @override
  List<Object?> get props => [id];
}
