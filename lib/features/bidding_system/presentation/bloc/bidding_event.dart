part of 'bidding_bloc.dart';

abstract class BiddingEvent extends Equatable {
  const BiddingEvent();

  @override
  List<Object?> get props => [];
}

class CreateTripEvent extends BiddingEvent {
  final CreateBiddingTripParams params;

  const CreateTripEvent(this.params);

  @override
  List<Object?> get props => [params];
}

class FetchOffersEvent extends BiddingEvent {
  final int tripId;
  final bool silent;

  const FetchOffersEvent(this.tripId, {this.silent = false});

  @override
  List<Object?> get props => [tripId, silent];
}

class AcceptOfferEvent extends BiddingEvent {
  final int offerId;

  const AcceptOfferEvent(this.offerId);

  @override
  List<Object?> get props => [offerId];
}

class SetCurrentTripEvent extends BiddingEvent {
  final BiddingTrip trip;

  const SetCurrentTripEvent(this.trip);

  @override
  List<Object?> get props => [trip];
}

class ResetBiddingEvent extends BiddingEvent {
  const ResetBiddingEvent();
}
