import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:motorent/features/bidding_system/domain/entities/bidding_offer.dart';
import 'package:motorent/features/bidding_system/domain/entities/bidding_trip.dart';
import 'package:motorent/features/bidding_system/domain/usecases/accept_bidding_offer.dart';
import 'package:motorent/features/bidding_system/domain/usecases/cancel_bidding_trip.dart';
import 'package:motorent/features/bidding_system/domain/usecases/fetch_bidding_offers.dart';
import 'package:motorent/features/bidding_system/domain/usecases/get_bidding_trip_details.dart';
import 'package:motorent/features/bidding_system/domain/usecases/get_my_bidding_trips.dart';

part 'trip_tracking_event.dart';
part 'trip_tracking_state.dart';

class TripTrackingBloc extends Bloc<TripTrackingEvent, TripTrackingState> {
  final GetMyBiddingTrips getMyBiddingTrips;
  final GetBiddingTripDetails getBiddingTripDetails;
  final CancelBiddingTrip cancelBiddingTrip;
  final FetchBiddingOffers fetchBiddingOffers;
  final AcceptBiddingOffer acceptBiddingOffer;

  BiddingTrip? _currentDetails;
  List<BiddingOffer> _currentOffers = const [];

  TripTrackingBloc({
    required this.getMyBiddingTrips,
    required this.getBiddingTripDetails,
    required this.cancelBiddingTrip,
    required this.fetchBiddingOffers,
    required this.acceptBiddingOffer,
  }) : super(const TrackingInitial()) {
    on<FetchMyTripsEvent>(_onFetchMyTrips);
    on<FetchTripDetailsEvent>(_onFetchTripDetails);
    on<AcceptTripOfferEvent>(_onAcceptOffer);
    on<CancelTripEvent>(_onCancelTrip);
  }

  Future<void> _onFetchMyTrips(
    FetchMyTripsEvent event,
    Emitter<TripTrackingState> emit,
  ) async {
    emit(const TrackingLoading(message: 'جاري تحميل الطلبات...'));

    final result = await getMyBiddingTrips();
    result.fold(
      (failure) => emit(TrackingError(failure.message)),
      (trips) => emit(TripsLoadedSuccess(trips)),
    );
  }

  Future<void> _onFetchTripDetails(
    FetchTripDetailsEvent event,
    Emitter<TripTrackingState> emit,
  ) async {
    if (!event.silent || _currentDetails == null) {
      emit(const TrackingLoading(message: 'جاري تحميل التفاصيل...'));
    }

    final result = await getBiddingTripDetails(event.id);
    await result.fold(
      (failure) async {
        if (!event.silent) {
          emit(TrackingError(failure.message));
        }
      },
      (trip) async {
        _currentDetails = trip;
        var offers = _currentOffers;
        if (trip.isPending) {
          final offersResult = await fetchBiddingOffers(trip.id);
          offersResult.fold((_) {}, (fresh) => offers = fresh);
        } else {
          offers = const [];
        }
        _currentOffers = offers;
        emit(TripDetailsLoadedSuccess(trip, offers: offers));
      },
    );
  }

  Future<void> _onAcceptOffer(
    AcceptTripOfferEvent event,
    Emitter<TripTrackingState> emit,
  ) async {
    final previous = _currentDetails;
    if (previous != null) {
      emit(TripDetailsLoadedSuccess(
        previous,
        offers: _currentOffers,
        acceptingOfferId: event.offerId,
      ));
    }

    final result = await acceptBiddingOffer(event.offerId);
    result.fold(
      (failure) {
        emit(TrackingError(failure.message));
        if (previous != null) {
          emit(TripDetailsLoadedSuccess(previous, offers: _currentOffers));
        }
      },
      (trip) {
        _currentDetails = trip;
        _currentOffers = const [];
        emit(TripOfferAcceptedSuccess(trip));
        emit(TripDetailsLoadedSuccess(trip));
      },
    );
  }

  Future<void> _onCancelTrip(
    CancelTripEvent event,
    Emitter<TripTrackingState> emit,
  ) async {
    final previous = _currentDetails;
    if (previous != null) {
      emit(TripDetailsLoadedSuccess(
        previous,
        offers: _currentOffers,
        cancelling: true,
      ));
    } else {
      emit(const TrackingLoading(message: 'جاري إلغاء الطلب...'));
    }

    final result = await cancelBiddingTrip(event.id);
    result.fold(
      (failure) {
        emit(TrackingError(failure.message));
        if (previous != null) {
          emit(TripDetailsLoadedSuccess(previous, offers: _currentOffers));
        }
      },
      (trip) {
        final cancelled = trip.status == 'cancelled'
            ? trip
            : (previous ?? trip).copyWith(status: 'cancelled');
        _currentDetails = cancelled;
        emit(TripCancelledSuccess(
          trip: cancelled,
          message: 'تم إلغاء الطلب بنجاح',
        ));
        emit(TripDetailsLoadedSuccess(cancelled));
      },
    );
  }
}
