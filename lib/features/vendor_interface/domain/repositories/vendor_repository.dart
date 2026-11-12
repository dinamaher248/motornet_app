import 'dart:io';

import 'package:motorent/features/vendor_interface/core/error/failures.dart';
import 'package:motorent/features/vendor_interface/core/utils/either.dart';
import 'package:motorent/features/vendor_interface/domain/entities/vendor_entities.dart';

abstract class VendorRepository {
  Future<Either<Failure, VendorStore>> fetchStore();

  Future<Either<Failure, VendorStore>> updateStore(UpdateVendorStoreParams params);

  Future<Either<Failure, List<VendorProduct>>> fetchProducts();

  Future<Either<Failure, VendorProduct>> createProduct(
    CreateVendorProductParams params,
  );

  Future<Either<Failure, VendorProduct>> updateProduct(
    UpdateVendorProductParams params,
  );

  Future<Either<Failure, void>> deleteProduct(int productId);

  Future<Either<Failure, VendorProduct>> toggleProduct(int productId);

  Future<Either<Failure, List<VendorOrder>>> fetchOrders();

  Future<Either<Failure, VendorOrder>> handleOrder({
    required int orderId,
    required String action,
    String orderType = 'normal',
  });

  Future<Either<Failure, VendorOrder>> sendCustomOffer(
    SendCustomOfferParams params,
  );

  Future<Either<Failure, VendorWallet>> fetchWallet();

  Future<Either<Failure, VendorWallet>> updateBillingMode(String billingMode);

  Future<Either<Failure, Unit>> settleWallet({
    required File receipt,
    required double amount,
  });
}
