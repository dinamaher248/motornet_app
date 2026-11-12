import 'dart:io';

import 'package:motorent/features/driver_interface/core/error/failures.dart';
import 'package:motorent/features/driver_interface/core/utils/either.dart';
import 'package:motorent/features/driver_interface/domain/entities/driver_entities.dart';

abstract class DriverRepository {
  Future<Either<Failure, bool>> toggleOnline(bool online);

  Future<Either<Failure, List<DriverTrip>>> fetchAvailableBids();

  Future<Either<Failure, bool>> makeOffer({
    required int tripId,
    required String type,
    required double amount,
  });

  Future<Either<Failure, Unit>> declineTrip({
    required int tripId,
    required String type,
  });

  Future<Either<Failure, List<DriverTrip>>> fetchMyTrips();

  Future<Either<Failure, DriverWallet>> fetchWallet();

  Future<Either<Failure, DriverWallet>> updateBillingMode(String billingMode);

  Future<Either<Failure, Unit>> settleWallet({
    required File receipt,
    required double amount,
  });
}
