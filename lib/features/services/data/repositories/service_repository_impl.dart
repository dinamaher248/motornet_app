import 'package:motorent/features/services/core/error/exceptions.dart';
import 'package:motorent/features/services/core/error/failures.dart';
import 'package:motorent/features/services/core/utils/either.dart';
import 'package:motorent/features/services/data/datasources/service_remote_data_source.dart';
import 'package:motorent/features/services/domain/entities/service_entities.dart';
import 'package:motorent/features/services/domain/repositories/service_repository.dart';

class ServiceRepositoryImpl implements ServiceRepository {
  final ServiceRemoteDataSource remoteDataSource;

  const ServiceRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<Store>>> fetchStores({
    required String category,
    double? lat,
    double? lng,
    String? listingKind,
  }) async {
    try {
      final stores = await remoteDataSource.fetchStores(
        category: category,
        lat: lat,
        lng: lng,
        listingKind: listingKind,
      );
      return Right(stores);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, statusCode: e.statusCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(UnexpectedFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Store>> fetchStoreDetails(
    int id, {
    double? lat,
    double? lng,
  }) async {
    try {
      final store = await remoteDataSource.fetchStoreDetails(
        id,
        lat: lat,
        lng: lng,
      );
      return Right(store);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, statusCode: e.statusCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(UnexpectedFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, ServiceOrder>> checkout(CheckoutParams params) async {
    try {
      final order = await remoteDataSource.checkout(params);
      return Right(order);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, statusCode: e.statusCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(UnexpectedFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, CustomOrder>> submitCustomOrder(
    SubmitCustomOrderParams params,
  ) async {
    try {
      final order = await remoteDataSource.submitCustomOrder(params);
      return Right(order);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, statusCode: e.statusCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(UnexpectedFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, CustomOrder>> respondToCustomOffer({
    required int orderId,
    required String action,
  }) async {
    try {
      final order = await remoteDataSource.respondToCustomOffer(
        orderId: orderId,
        action: action,
      );
      return Right(order);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, statusCode: e.statusCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(UnexpectedFailure(e.toString()));
    }
  }
}
