import 'dart:io';

import 'package:motorent/features/my_account/core/error/failures.dart';
import 'package:motorent/features/my_account/core/utils/either.dart';
import 'package:motorent/features/my_account/domain/entities/profile_data.dart';
import 'package:motorent/features/my_account/domain/repositories/profile_repository.dart';

class UpdateProfile {
  final ProfileRepository repository;
  const UpdateProfile(this.repository);

  Future<Either<Failure, ProfileUser>> call({
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
  }) {
    return repository.updateProfile(
      name: name,
      phone: phone,
      email: email,
      vehicleType: vehicleType,
      password: password,
      passwordConfirmation: passwordConfirmation,
      governorate: governorate,
      area: area,
      imageFile: imageFile,
      nidImageFile: nidImageFile,
    );
  }
}
