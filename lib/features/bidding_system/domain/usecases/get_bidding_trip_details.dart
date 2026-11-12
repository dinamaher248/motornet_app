import 'package:motorent/features/bidding_system/core/error/failures.dart';
import 'package:motorent/features/bidding_system/core/utils/either.dart';
import 'package:motorent/features/bidding_system/domain/entities/bidding_trip.dart';
import 'package:motorent/features/bidding_system/domain/repositories/bidding_repository.dart';

class GetBiddingTripDetails {
  final BiddingRepository repository;

  const GetBiddingTripDetails(this.repository);

  Future<Either<Failure, BiddingTrip>> call(int tripId) {
    return repository.getTripDetails(tripId);
  }
}
