import 'package:motorent/features/bidding_system/core/error/failures.dart';
import 'package:motorent/features/bidding_system/core/utils/either.dart';
import 'package:motorent/features/bidding_system/domain/entities/bidding_offer.dart';
import 'package:motorent/features/bidding_system/domain/repositories/bidding_repository.dart';

class FetchBiddingOffers {
  final BiddingRepository repository;

  const FetchBiddingOffers(this.repository);

  Future<Either<Failure, List<BiddingOffer>>> call(int tripId) {
    return repository.fetchOffers(tripId);
  }
}
