part of 'trip_tracking_bloc.dart';

abstract class TripTrackingState extends Equatable {
  const TripTrackingState();

  @override
  List<Object?> get props => [];
}

class TrackingInitial extends TripTrackingState {
  const TrackingInitial();
}

class TrackingLoading extends TripTrackingState {
  final String? message;

  const TrackingLoading({this.message});

  @override
  List<Object?> get props => [message];
}

class TripsLoadedSuccess extends TripTrackingState {
  final List<BiddingTrip> trips;

  const TripsLoadedSuccess(this.trips);

  @override
  List<Object?> get props => [trips];
}

class TripDetailsLoadedSuccess extends TripTrackingState {
  final BiddingTrip trip;
  final List<BiddingOffer> offers;
  final bool cancelling;
  final int? acceptingOfferId;

  const TripDetailsLoadedSuccess(
    this.trip, {
    this.offers = const [],
    this.cancelling = false,
    this.acceptingOfferId,
  });

  @override
  List<Object?> get props => [trip, offers, cancelling, acceptingOfferId];
}

class TripOfferAcceptedSuccess extends TripTrackingState {
  final BiddingTrip trip;

  const TripOfferAcceptedSuccess(this.trip);

  @override
  List<Object?> get props => [trip];
}

class TripCancelledSuccess extends TripTrackingState {
  final BiddingTrip trip;
  final String message;

  const TripCancelledSuccess({
    required this.trip,
    this.message = 'تم إلغاء الطلب بنجاح',
  });

  @override
  List<Object?> get props => [trip, message];
}

class TrackingError extends TripTrackingState {
  final String message;

  const TrackingError(this.message);

  @override
  List<Object?> get props => [message];
}
