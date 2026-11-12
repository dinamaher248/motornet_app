import 'package:motorent/features/services/data/datasources/service_remote_data_source.dart';
import 'package:motorent/features/services/data/repositories/service_repository_impl.dart';
import 'package:motorent/features/services/domain/repositories/service_repository.dart';
import 'package:motorent/features/services/presentation/bloc/custom_order_bloc.dart';
import 'package:motorent/features/services/presentation/bloc/service_bloc.dart';

class ServicesInjection {
  ServicesInjection._();

  static ServiceRepository createRepository() {
    return ServiceRepositoryImpl(
      remoteDataSource: ServiceRemoteDataSourceImpl(),
    );
  }

  static ServiceBloc createBloc() {
    return ServiceBloc(repository: createRepository());
  }

  static CustomOrderBloc createCustomOrderBloc() {
    return CustomOrderBloc(repository: createRepository());
  }
}
