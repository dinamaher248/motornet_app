import 'package:motorent/features/my_account/core/error/failures.dart';
import 'package:motorent/features/my_account/core/utils/either.dart';
import 'package:motorent/features/my_account/domain/entities/profile_data.dart';
import 'package:motorent/features/my_account/domain/repositories/profile_repository.dart';

class GetProfile {
  final ProfileRepository repository;
  const GetProfile(this.repository);

  Future<Either<Failure, ProfileData>> call() => repository.getProfile();
}
