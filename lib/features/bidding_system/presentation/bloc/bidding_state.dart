part of 'bidding_bloc.dart';

abstract class BiddingState extends Equatable {
  const BiddingState();

  @override
  List<Object?> get props => [];
}

class BiddingInitial extends BiddingState {
  const BiddingInitial();
}

class BiddingLoading extends BiddingState {
  final String? message;

  const BiddingLoading({this.message});

  @override
  List<Object?> get props => [message];
}

class TripCreatedSuccess extends BiddingState {
  final BiddingTrip trip;

  const TripCreatedSuccess(this.trip);

  @override
  List<Object?> get props => [trip];
}

class OffersLoadedSuccess extends BiddingState {
  final BiddingTrip trip;
  final List<BiddingOffer> offers;
  final bool isRefreshing;

  const OffersLoadedSuccess({
    required this.trip,
    required this.offers,
    this.isRefreshing = false,
  });

  @override
  List<Object?> get props => [trip, offers, isRefreshing];
}

class OfferAcceptedSuccess extends BiddingState {
  final BiddingTrip trip;

  const OfferAcceptedSuccess(this.trip);

  @override
  List<Object?> get props => [trip];
}

class BiddingError extends BiddingState {
  final String message;

  const BiddingError(this.message);

  @override
  List<Object?> get props => [message];
}
