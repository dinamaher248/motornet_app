import 'package:motorent/features/bidding_system/core/error/exceptions.dart';
import 'package:motorent/features/bidding_system/core/error/failures.dart';
import 'package:motorent/features/bidding_system/core/utils/either.dart';
import 'package:motorent/features/bidding_system/data/datasources/bidding_remote_data_source.dart';
import 'package:motorent/features/bidding_system/domain/entities/bidding_offer.dart';
import 'package:motorent/features/bidding_system/domain/entities/bidding_trip.dart';
import 'package:motorent/features/bidding_system/domain/entities/create_bidding_trip_params.dart';
import 'package:motorent/features/bidding_system/domain/repositories/bidding_repository.dart';

class BiddingRepositoryImpl implements BiddingRepository {
  final BiddingRemoteDataSource remoteDataSource;

  const BiddingRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, BiddingTrip>> createTrip(
    CreateBiddingTripParams params,
  ) async {
    try {
      final trip = await remoteDataSource.createTrip(params);
      return Right(trip);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, statusCode: e.statusCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(UnexpectedFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<BiddingOffer>>> fetchOffers(int tripId) async {
    try {
      final offers = await remoteDataSource.fetchOffers(tripId);
      return Right(offers);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, statusCode: e.statusCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(UnexpectedFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, BiddingTrip>> acceptOffer(int offerId) async {
    try {
      final trip = await remoteDataSource.acceptOffer(offerId);
      return Right(trip);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, statusCode: e.statusCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(UnexpectedFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, BiddingTrip>> fetchTrip(int tripId) async {
    try {
      final trip = await remoteDataSource.fetchTrip(tripId);
      return Right(trip);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, statusCode: e.statusCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(UnexpectedFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<BiddingTrip>>> getMyTrips() async {
    try {
      final trips = await remoteDataSource.getMyTrips();
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
  Future<Either<Failure, BiddingTrip>> getTripDetails(int tripId) async {
    try {
      final trip = await remoteDataSource.getTripDetails(tripId);
      return Right(trip);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, statusCode: e.statusCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(UnexpectedFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, BiddingTrip>> cancelTrip(int tripId) async {
    try {
      final trip = await remoteDataSource.cancelTrip(tripId);
      return Right(trip);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, statusCode: e.statusCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(UnexpectedFailure(e.toString()));
    }
  }
}
