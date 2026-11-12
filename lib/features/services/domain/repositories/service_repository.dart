import 'package:motorent/features/services/core/error/failures.dart';
import 'package:motorent/features/services/core/utils/either.dart';
import 'package:motorent/features/services/domain/entities/service_entities.dart';

abstract class ServiceRepository {
  Future<Either<Failure, List<Store>>> fetchStores({
    required String category,
    double? lat,
    double? lng,
    String? listingKind,
  });

  Future<Either<Failure, Store>> fetchStoreDetails(
    int id, {
    double? lat,
    double? lng,
  });

  Future<Either<Failure, ServiceOrder>> checkout(CheckoutParams params);

  Future<Either<Failure, CustomOrder>> submitCustomOrder(
    SubmitCustomOrderParams params,
  );

  Future<Either<Failure, CustomOrder>> respondToCustomOffer({
    required int orderId,
    required String action, // 'accept' | 'reject'
  });
}
