part of 'driver_home_bloc.dart';

abstract class DriverHomeEvent extends Equatable {
  const DriverHomeEvent();
  @override
  List<Object?> get props => [];
}

class LoadDriverHomeEvent extends DriverHomeEvent {
  final bool silent;
  const LoadDriverHomeEvent({this.silent = false});

  @override
  List<Object?> get props => [silent];
}

class RefreshAvailableBidsEvent extends DriverHomeEvent {
  final bool silent;
  const RefreshAvailableBidsEvent({this.silent = false});

  @override
  List<Object?> get props => [silent];
}

class ToggleOnlineEvent extends DriverHomeEvent {
  final bool online;
  const ToggleOnlineEvent(this.online);
  @override
  List<Object?> get props => [online];
}

class MakeOfferEvent extends DriverHomeEvent {
  final int tripId;
  final String type;
  final double amount;

  const MakeOfferEvent({
    required this.tripId,
    required this.type,
    required this.amount,
  });

  @override
  List<Object?> get props => [tripId, type, amount];
}

class DeclineTripEvent extends DriverHomeEvent {
  final int tripId;
  final String type;

  const DeclineTripEvent({
    required this.tripId,
    required this.type,
  });

  @override
  List<Object?> get props => [tripId, type];
}
