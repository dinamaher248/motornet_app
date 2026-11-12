import 'package:motorent/features/bidding_system/core/error/failures.dart';
import 'package:motorent/features/bidding_system/core/utils/either.dart';
import 'package:motorent/features/bidding_system/domain/entities/bidding_trip.dart';
import 'package:motorent/features/bidding_system/domain/entities/create_bidding_trip_params.dart';
import 'package:motorent/features/bidding_system/domain/repositories/bidding_repository.dart';

class CreateBiddingTrip {
  final BiddingRepository repository;

  const CreateBiddingTrip(this.repository);

  Future<Either<Failure, BiddingTrip>> call(CreateBiddingTripParams params) {
    return repository.createTrip(params);
  }
}
