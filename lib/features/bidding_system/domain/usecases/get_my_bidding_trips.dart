import 'package:motorent/features/bidding_system/core/error/failures.dart';
import 'package:motorent/features/bidding_system/core/utils/either.dart';
import 'package:motorent/features/bidding_system/domain/entities/bidding_trip.dart';
import 'package:motorent/features/bidding_system/domain/repositories/bidding_repository.dart';

class GetMyBiddingTrips {
  final BiddingRepository repository;

  const GetMyBiddingTrips(this.repository);

  Future<Either<Failure, List<BiddingTrip>>> call() {
    return repository.getMyTrips();
  }
}
