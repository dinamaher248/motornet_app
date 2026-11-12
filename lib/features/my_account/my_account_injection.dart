import 'package:motorent/features/my_account/data/datasources/profile_remote_data_source.dart';
import 'package:motorent/features/my_account/data/repositories/profile_repository_impl.dart';
import 'package:motorent/features/my_account/domain/repositories/profile_repository.dart';
import 'package:motorent/features/my_account/domain/usecases/get_profile.dart';
import 'package:motorent/features/my_account/domain/usecases/update_profile.dart';
import 'package:motorent/features/my_account/presentation/bloc/profile_bloc.dart';

class MyAccountInjection {
  MyAccountInjection._();

  static ProfileRepository createRepository() {
    return ProfileRepositoryImpl(
      remoteDataSource: ProfileRemoteDataSourceImpl(),
    );
  }

  static ProfileBloc createBloc() {
    final repository = createRepository();
    return ProfileBloc(
      getProfile: GetProfile(repository),
      updateProfile: UpdateProfile(repository),
    );
  }
}
