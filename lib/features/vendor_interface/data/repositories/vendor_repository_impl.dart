import 'dart:io';

import 'package:motorent/features/vendor_interface/core/error/exceptions.dart';
import 'package:motorent/features/vendor_interface/core/error/failures.dart';
import 'package:motorent/features/vendor_interface/core/utils/either.dart';
import 'package:motorent/features/vendor_interface/data/datasources/vendor_remote_data_source.dart';
import 'package:motorent/features/vendor_interface/domain/entities/vendor_entities.dart';
import 'package:motorent/features/vendor_interface/domain/repositories/vendor_repository.dart';

class VendorRepositoryImpl implements VendorRepository {
  final VendorRemoteDataSource remoteDataSource;

  const VendorRepositoryImpl({required this.remoteDataSource});

  Future<Either<Failure, T>> _catch<T>(Future<T> Function() run) async {
    try {
      return Right(await run());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, statusCode: e.statusCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(UnexpectedFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, VendorStore>> fetchStore() =>
      _catch(() => remoteDataSource.fetchStore());

  @override
  Future<Either<Failure, VendorStore>> updateStore(
    UpdateVendorStoreParams params,
  ) =>
      _catch(() => remoteDataSource.updateStore(params));

  @override
  Future<Either<Failure, List<VendorProduct>>> fetchProducts() =>
      _catch(() => remoteDataSource.fetchProducts());

  @override
  Future<Either<Failure, VendorProduct>> createProduct(
    CreateVendorProductParams params,
  ) =>
      _catch(() => remoteDataSource.createProduct(params));

  @override
  Future<Either<Failure, VendorProduct>> updateProduct(
    UpdateVendorProductParams params,
  ) =>
      _catch(() => remoteDataSource.updateProduct(params));

  @override
  Future<Either<Failure, void>> deleteProduct(int productId) =>
      _catch(() => remoteDataSource.deleteProduct(productId));

  @override
  Future<Either<Failure, VendorProduct>> toggleProduct(int productId) =>
      _catch(() => remoteDataSource.toggleProduct(productId));

  @override
  Future<Either<Failure, List<VendorOrder>>> fetchOrders() =>
      _catch(() => remoteDataSource.fetchOrders());

  @override
  Future<Either<Failure, VendorOrder>> handleOrder({
    required int orderId,
    required String action,
    String orderType = 'normal',
  }) =>
      _catch(
        () => remoteDataSource.handleOrder(
          orderId: orderId,
          action: action,
          orderType: orderType,
        ),
      );

  @override
  Future<Either<Failure, VendorOrder>> sendCustomOffer(
    SendCustomOfferParams params,
  ) =>
      _catch(() => remoteDataSource.sendCustomOffer(params));

  @override
  Future<Either<Failure, VendorWallet>> fetchWallet() =>
      _catch(() => remoteDataSource.fetchWallet());

  @override
  Future<Either<Failure, VendorWallet>> updateBillingMode(String billingMode) =>
      _catch(() => remoteDataSource.updateBillingMode(billingMode));

  @override
  Future<Either<Failure, Unit>> settleWallet({
    required File receipt,
    required double amount,
  }) async {
    try {
      await remoteDataSource.settleWallet(receipt: receipt, amount: amount);
      return const Right(unit);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, statusCode: e.statusCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(UnexpectedFailure(e.toString()));
    }
  }
}
