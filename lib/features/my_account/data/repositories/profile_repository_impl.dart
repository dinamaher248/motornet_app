import 'dart:io';

import 'package:motorent/features/my_account/core/error/exceptions.dart';
import 'package:motorent/features/my_account/core/error/failures.dart';
import 'package:motorent/features/my_account/core/utils/either.dart';
import 'package:motorent/features/my_account/data/datasources/profile_remote_data_source.dart';
import 'package:motorent/features/my_account/domain/entities/profile_data.dart';
import 'package:motorent/features/my_account/domain/repositories/profile_repository.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  final ProfileRemoteDataSource remoteDataSource;

  const ProfileRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, ProfileData>> getProfile() async {
    try {
      final data = await remoteDataSource.getProfile();
      return Right(data);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, statusCode: e.statusCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(UnexpectedFailure(e.toString()));
    }
  }

  @override
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
  }) async {
    try {
      final user = await remoteDataSource.updateProfile(
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
      return Right(user);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, statusCode: e.statusCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(UnexpectedFailure(e.toString()));
    }
  }
}
