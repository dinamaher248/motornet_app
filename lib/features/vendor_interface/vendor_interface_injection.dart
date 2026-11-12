import 'package:motorent/features/vendor_interface/data/datasources/vendor_remote_data_source.dart';
import 'package:motorent/features/vendor_interface/data/repositories/vendor_repository_impl.dart';
import 'package:motorent/features/vendor_interface/domain/repositories/vendor_repository.dart';
import 'package:motorent/features/vendor_interface/presentation/bloc/vendor_orders_bloc.dart';
import 'package:motorent/features/vendor_interface/presentation/bloc/vendor_products_bloc.dart';
import 'package:motorent/features/vendor_interface/presentation/bloc/vendor_store_bloc.dart';
import 'package:motorent/features/vendor_interface/presentation/bloc/vendor_wallet_bloc.dart';

class VendorInterfaceInjection {
  VendorInterfaceInjection._();

  static VendorRepository createRepository() {
    return VendorRepositoryImpl(
      remoteDataSource: VendorRemoteDataSourceImpl(),
    );
  }

  static VendorStoreBloc createStoreBloc() =>
      VendorStoreBloc(repository: createRepository());

  static VendorProductsBloc createProductsBloc() =>
      VendorProductsBloc(repository: createRepository());

  static VendorOrdersBloc createOrdersBloc() =>
      VendorOrdersBloc(repository: createRepository());

  static VendorWalletBloc createWalletBloc() =>
      VendorWalletBloc(repository: createRepository());
}
