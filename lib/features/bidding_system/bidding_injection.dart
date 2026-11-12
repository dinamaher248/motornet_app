import 'package:motorent/features/bidding_system/data/datasources/bidding_remote_data_source.dart';
import 'package:motorent/features/bidding_system/data/repositories/bidding_repository_impl.dart';
import 'package:motorent/features/bidding_system/domain/repositories/bidding_repository.dart';
import 'package:motorent/features/bidding_system/domain/usecases/accept_bidding_offer.dart';
import 'package:motorent/features/bidding_system/domain/usecases/cancel_bidding_trip.dart';
import 'package:motorent/features/bidding_system/domain/usecases/create_bidding_trip.dart';
import 'package:motorent/features/bidding_system/domain/usecases/fetch_bidding_offers.dart';
import 'package:motorent/features/bidding_system/domain/usecases/get_bidding_trip_details.dart';
import 'package:motorent/features/bidding_system/domain/usecases/get_my_bidding_trips.dart';
import 'package:motorent/features/bidding_system/presentation/bloc/bidding_bloc.dart';
import 'package:motorent/features/bidding_system/presentation/bloc/trip_tracking_bloc.dart';

/// Simple composition root for the bidding feature (no DI package required).
class BiddingInjection {
  BiddingInjection._();

  static BiddingRepository createRepository() {
    return BiddingRepositoryImpl(
      remoteDataSource: BiddingRemoteDataSourceImpl(),
    );
  }

  static BiddingBloc createBloc() {
    final repository = createRepository();
    return BiddingBloc(
      createBiddingTrip: CreateBiddingTrip(repository),
      fetchBiddingOffers: FetchBiddingOffers(repository),
      acceptBiddingOffer: AcceptBiddingOffer(repository),
    );
  }

  static TripTrackingBloc createTrackingBloc() {
    final repository = createRepository();
    return TripTrackingBloc(
      getMyBiddingTrips: GetMyBiddingTrips(repository),
      getBiddingTripDetails: GetBiddingTripDetails(repository),
      cancelBiddingTrip: CancelBiddingTrip(repository),
      fetchBiddingOffers: FetchBiddingOffers(repository),
      acceptBiddingOffer: AcceptBiddingOffer(repository),
    );
  }
}
