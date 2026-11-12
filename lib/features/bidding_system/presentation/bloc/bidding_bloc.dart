import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:motorent/features/bidding_system/domain/entities/bidding_offer.dart';
import 'package:motorent/features/bidding_system/domain/entities/bidding_trip.dart';
import 'package:motorent/features/bidding_system/domain/entities/create_bidding_trip_params.dart';
import 'package:motorent/features/bidding_system/domain/usecases/accept_bidding_offer.dart';
import 'package:motorent/features/bidding_system/domain/usecases/create_bidding_trip.dart';
import 'package:motorent/features/bidding_system/domain/usecases/fetch_bidding_offers.dart';

part 'bidding_event.dart';
part 'bidding_state.dart';

class BiddingBloc extends Bloc<BiddingEvent, BiddingState> {
  final CreateBiddingTrip createBiddingTrip;
  final FetchBiddingOffers fetchBiddingOffers;
  final AcceptBiddingOffer acceptBiddingOffer;

  BiddingTrip? _currentTrip;

  BiddingBloc({
    required this.createBiddingTrip,
    required this.fetchBiddingOffers,
    required this.acceptBiddingOffer,
  }) : super(const BiddingInitial()) {
    on<CreateTripEvent>(_onCreateTrip);
    on<FetchOffersEvent>(_onFetchOffers);
    on<AcceptOfferEvent>(_onAcceptOffer);
    on<SetCurrentTripEvent>(_onSetCurrentTrip);
    on<ResetBiddingEvent>(_onReset);
  }

  BiddingTrip? get currentTrip => _currentTrip;

  void _onSetCurrentTrip(
    SetCurrentTripEvent event,
    Emitter<BiddingState> emit,
  ) {
    _currentTrip = event.trip;
  }

  Future<void> _onCreateTrip(
    CreateTripEvent event,
    Emitter<BiddingState> emit,
  ) async {
    emit(const BiddingLoading(message: 'جاري إنشاء الطلب...'));

    final result = await createBiddingTrip(event.params);
    result.fold(
      (failure) => emit(BiddingError(failure.message)),
      (trip) {
        _currentTrip = trip;
        emit(TripCreatedSuccess(trip));
      },
    );
  }

  Future<void> _onFetchOffers(
    FetchOffersEvent event,
    Emitter<BiddingState> emit,
  ) async {
    final previous = state;
    if (!event.silent) {
      emit(const BiddingLoading(message: 'جاري تحميل العروض...'));
    } else if (previous is OffersLoadedSuccess) {
      emit(OffersLoadedSuccess(
        trip: previous.trip,
        offers: previous.offers,
        isRefreshing: true,
      ));
    }

    final result = await fetchBiddingOffers(event.tripId);
    result.fold(
      (failure) {
        if (!event.silent) {
          emit(BiddingError(failure.message));
        } else if (previous is OffersLoadedSuccess) {
          emit(previous);
        }
      },
      (offers) {
        final trip = _currentTrip ??
            BiddingTrip(
              id: event.tripId,
              userId: 0,
              vehicleType: '',
              pickupAddress: '',
              dropoffAddress: '',
              description: '',
              phone: '',
              status: 'pending',
            );
        final pending = offers.where((o) => o.isPending).toList();
        emit(OffersLoadedSuccess(trip: trip, offers: pending));
      },
    );
  }

  Future<void> _onAcceptOffer(
    AcceptOfferEvent event,
    Emitter<BiddingState> emit,
  ) async {
    emit(const BiddingLoading(message: 'جاري قبول العرض...'));

    final result = await acceptBiddingOffer(event.offerId);
    result.fold(
      (failure) => emit(BiddingError(failure.message)),
      (trip) {
        _currentTrip = trip;
        emit(OfferAcceptedSuccess(trip));
      },
    );
  }

  void _onReset(ResetBiddingEvent event, Emitter<BiddingState> emit) {
    _currentTrip = null;
    emit(const BiddingInitial());
  }
}
