part of 'driver_home_bloc.dart';

enum DriverHomeStatus { initial, loading, loaded, failure }

class DriverHomeState extends Equatable {
  final DriverHomeStatus status;
  final bool isOnline;
  final bool togglingOnline;
  final bool submittingOffer;
  final bool offerSuccess;
  final bool tripStarted;
  final bool hasActiveTrip;
  final List<DriverTrip> trips;
  final String? message;

  const DriverHomeState({
    this.status = DriverHomeStatus.initial,
    this.isOnline = false,
    this.togglingOnline = false,
    this.submittingOffer = false,
    this.offerSuccess = false,
    this.tripStarted = false,
    this.hasActiveTrip = false,
    this.trips = const [],
    this.message,
  });

  DriverHomeState copyWith({
    DriverHomeStatus? status,
    bool? isOnline,
    bool? togglingOnline,
    bool? submittingOffer,
    bool? offerSuccess,
    bool? tripStarted,
    bool? hasActiveTrip,
    List<DriverTrip>? trips,
    String? message,
    bool clearMessage = false,
  }) {
    return DriverHomeState(
      status: status ?? this.status,
      isOnline: isOnline ?? this.isOnline,
      togglingOnline: togglingOnline ?? this.togglingOnline,
      submittingOffer: submittingOffer ?? this.submittingOffer,
      offerSuccess: offerSuccess ?? false,
      tripStarted: tripStarted ?? false,
      hasActiveTrip: hasActiveTrip ?? this.hasActiveTrip,
      trips: trips ?? this.trips,
      message: clearMessage ? null : (message ?? this.message),
    );
  }

  @override
  List<Object?> get props => [
        status,
        isOnline,
        togglingOnline,
        submittingOffer,
        offerSuccess,
        tripStarted,
        hasActiveTrip,
        trips,
        message,
      ];
}
