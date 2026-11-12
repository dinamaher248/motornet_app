import 'dart:io';

import 'package:motorent/features/driver_interface/core/error/exceptions.dart';
import 'package:motorent/features/driver_interface/core/error/failures.dart';
import 'package:motorent/features/driver_interface/core/utils/either.dart';
import 'package:motorent/features/driver_interface/data/datasources/driver_remote_data_source.dart';
import 'package:motorent/features/driver_interface/domain/entities/driver_entities.dart';
import 'package:motorent/features/driver_interface/domain/repositories/driver_repository.dart';

class DriverRepositoryImpl implements DriverRepository {
  final DriverRemoteDataSource remoteDataSource;

  const DriverRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, bool>> toggleOnline(bool online) async {
    try {
      final result = await remoteDataSource.toggleOnline(online);
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, statusCode: e.statusCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(UnexpectedFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<DriverTrip>>> fetchAvailableBids() async {
    try {
      final trips = await remoteDataSource.fetchAvailableBids();
      return Right(trips);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, statusCode: e.statusCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(UnexpectedFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> declineTrip({
    required int tripId,
    required String type,
  }) async {
    try {
      await remoteDataSource.declineTrip(tripId: tripId, type: type);
      return const Right(unit);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, statusCode: e.statusCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(UnexpectedFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> makeOffer({
    required int tripId,
    required String type,
    required double amount,
  }) async {
    try {
      final started = await remoteDataSource.makeOffer(
        tripId: tripId,
        type: type,
        amount: amount,
      );
      return Right(started);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, statusCode: e.statusCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(UnexpectedFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<DriverTrip>>> fetchMyTrips() async {
    try {
      final trips = await remoteDataSource.fetchMyTrips();
      return Right(trips);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, statusCode: e.statusCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(UnexpectedFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, DriverWallet>> fetchWallet() async {
    try {
      final wallet = await remoteDataSource.fetchWallet();
      return Right(wallet);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, statusCode: e.statusCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(UnexpectedFailure(e.toString()));
    }
  }

  @override
  @override
  Future<Either<Failure, DriverWallet>> updateBillingMode(
    String billingMode,
  ) async {
    try {
      final wallet = await remoteDataSource.updateBillingMode(billingMode);
      return Right(wallet);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, statusCode: e.statusCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(UnexpectedFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> settleWallet({
    required File receipt,
    required double amount,
  }) async {
    try {
      await remoteDataSource.settleWallet(receipt: receipt, amount: amount);
      return const Right(unit);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, statusCode: e.statusCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(UnexpectedFailure(e.toString()));
    }
  }
}
