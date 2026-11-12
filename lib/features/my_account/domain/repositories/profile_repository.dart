import 'dart:io';

import 'package:motorent/features/my_account/core/error/failures.dart';
import 'package:motorent/features/my_account/core/utils/either.dart';
import 'package:motorent/features/my_account/domain/entities/profile_data.dart';

abstract class ProfileRepository {
  Future<Either<Failure, ProfileData>> getProfile();

  Future<Either<Failure, ProfileUser>> updateProfile({
    String? name,
    String? phone,
    String? email,
    String? vehicleType,
    String? password,
    String? passwordConfirmation,
    String? governorate,
    String? area,
    File? imageFile,
    File? nidImageFile,
  });
}
