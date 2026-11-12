import 'package:motorent/features/bidding_system/core/error/failures.dart';
import 'package:motorent/features/bidding_system/core/utils/either.dart';
import 'package:motorent/features/bidding_system/domain/entities/bidding_offer.dart';
import 'package:motorent/features/bidding_system/domain/entities/bidding_trip.dart';
import 'package:motorent/features/bidding_system/domain/entities/create_bidding_trip_params.dart';

abstract class BiddingRepository {
  Future<Either<Failure, BiddingTrip>> createTrip(CreateBiddingTripParams params);

  Future<Either<Failure, List<BiddingOffer>>> fetchOffers(int tripId);

  Future<Either<Failure, BiddingTrip>> acceptOffer(int offerId);

  Future<Either<Failure, BiddingTrip>> fetchTrip(int tripId);

  Future<Either<Failure, List<BiddingTrip>>> getMyTrips();

  Future<Either<Failure, BiddingTrip>> getTripDetails(int tripId);

  Future<Either<Failure, BiddingTrip>> cancelTrip(int tripId);
}
