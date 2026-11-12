import 'package:motorent/features/driver_interface/data/datasources/driver_remote_data_source.dart';
import 'package:motorent/features/driver_interface/data/repositories/driver_repository_impl.dart';
import 'package:motorent/features/driver_interface/domain/repositories/driver_repository.dart';
import 'package:motorent/features/driver_interface/presentation/bloc/driver_home_bloc.dart';
import 'package:motorent/features/driver_interface/presentation/bloc/driver_wallet_bloc.dart';

class DriverInterfaceInjection {
  DriverInterfaceInjection._();

  static DriverRepository createRepository() {
    return DriverRepositoryImpl(
      remoteDataSource: DriverRemoteDataSourceImpl(),
    );
  }

  static DriverHomeBloc createHomeBloc() {
    return DriverHomeBloc(repository: createRepository());
  }

  static DriverWalletBloc createWalletBloc() {
    return DriverWalletBloc(repository: createRepository());
  }

  static DriverRepository get repository => createRepository();
}
