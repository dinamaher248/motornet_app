import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:motorent/data/local/auth_prefs.dart';
import 'package:motorent/data/local/cache_helper.dart';
import 'package:motorent/data/remote/url_api.dart';
import 'package:motorent/features/vendor_interface/core/error/exceptions.dart';
import 'package:motorent/features/vendor_interface/data/models/vendor_models.dart';
import 'package:motorent/features/vendor_interface/domain/entities/vendor_entities.dart';

abstract class VendorRemoteDataSource {
  Future<VendorStore> fetchStore();
  Future<VendorStore> updateStore(UpdateVendorStoreParams params);
  Future<List<VendorProduct>> fetchProducts();
  Future<VendorProduct> createProduct(CreateVendorProductParams params);
  Future<VendorProduct> updateProduct(UpdateVendorProductParams params);
  Future<void> deleteProduct(int productId);
  Future<VendorProduct> toggleProduct(int productId);
  Future<List<VendorOrder>> fetchOrders();
  Future<VendorOrder> handleOrder({
    required int orderId,
    required String action,
    String orderType = 'normal',
  });
  Future<VendorOrder> sendCustomOffer(SendCustomOfferParams params);
  Future<VendorWallet> fetchWallet();
  Future<VendorWallet> updateBillingMode(String billingMode);
  Future<void> settleWallet({required File receipt, required double amount});
}

class VendorRemoteDataSourceImpl implements VendorRemoteDataSource {
  final Dio dio;

  VendorRemoteDataSourceImpl({Dio? dio}) : dio = dio ?? Dio();

  Options get _auth => Options(
        headers: {
          'Authorization': 'Bearer ${CacheHelper.getData(key: 'token')}',
          'Accept': 'application/json',
        },
        sendTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        validateStatus: (status) => status != null && status < 600,
      );

  @override
  Future<VendorStore> fetchStore() async {
    try {
      var response = await dio.get(vendorStoreProfileEP, options: _auth);
      if (response.statusCode == 404) {
        return _fetchStoreLegacy();
      }
      if (response.statusCode != 200) {
        throw ServerException(_msg(response.data, 'تعذر تحميل بيانات النشاط'),
            statusCode: response.statusCode);
      }
      return _withFallbackCategories(_parseStore(response.data));
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return _fetchStoreLegacy();
      throw _mapDio(e, 'تعذر تحميل بيانات النشاط');
    }
  }

  Future<VendorStore> _fetchStoreLegacy() async {
    final profile = await dio.get(merchantProfileEP, options: _auth);
    if (profile.statusCode != 200) {
      throw ServerException(_msg(profile.data, 'تعذر تحميل بيانات النشاط'),
          statusCode: profile.statusCode);
    }
    Map<String, dynamic>? payment;
    try {
      final payRes = await dio.get(merchantPaymentMethodsEP, options: _auth);
      if (payRes.statusCode == 200) {
        final data = payRes.data;
        if (data is Map) {
          payment = Map<String, dynamic>.from(
            (data['data'] is Map) ? data['data'] as Map : data,
          );
        }
      }
    } catch (_) {}
    return _withFallbackCategories(
      _parseStore(profile.data, paymentOverride: payment),
    );
  }

  @override
  Future<VendorStore> updateStore(UpdateVendorStoreParams params) async {
    try {
      final map = await _storeFormMap(params);
      var response = await dio.post(
        vendorStoreUpdateEP,
        data: FormData.fromMap(map),
        options: _auth.copyWith(contentType: 'multipart/form-data'),
      );
      if (response.statusCode == 404) {
        return _updateStoreLegacy(params);
      }
      if (response.statusCode != 200 && response.statusCode != 201) {
        throw ServerException(_msg(response.data, 'تعذر حفظ بيانات النشاط'),
            statusCode: response.statusCode);
      }
      return _parseStore(response.data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return _updateStoreLegacy(params);
      throw _mapDio(e, 'تعذر حفظ بيانات النشاط');
    }
  }

  Future<VendorStore> _updateStoreLegacy(UpdateVendorStoreParams params) async {
    final map = await _storeFormMap(params);
    final profile = await dio.post(
      merchantProfileEP,
      data: FormData.fromMap({
        'category_id': params.categoryId,
        'name': params.name,
        'address': params.address,
        'phone': params.phone,
        'lat': params.lat.toStringAsFixed(7),
        'lng': params.lng.toStringAsFixed(7),
        'working_hours': map['working_hours'],
        if (map['image'] != null) 'image': map['image'],
      }),
      options: _auth.copyWith(contentType: 'multipart/form-data'),
    );
    if (profile.statusCode != 200) {
      throw ServerException(_msg(profile.data, 'تعذر حفظ بيانات النشاط'),
          statusCode: profile.statusCode);
    }

    final pay = await dio.post(
      merchantPaymentMethodsEP,
      data: {
        'pay_on_delivery': params.payOnDelivery ? 1 : 0,
        'pay_wallet': params.payWallet ? 1 : 0,
        if (params.walletNumber != null) 'wallet_number': params.walletNumber,
        if (params.walletOwnerName != null)
          'wallet_owner_name': params.walletOwnerName,
        if (params.walletType != null && params.walletType!.isNotEmpty)
          'wallet_type': params.walletType,
      },
      options: _auth,
    );
    if (pay.statusCode != 200) {
      throw ServerException(_msg(pay.data, 'تعذر حفظ طرق الدفع'),
          statusCode: pay.statusCode);
    }

    return _fetchStoreLegacy();
  }

  Future<Map<String, dynamic>> _storeFormMap(
    UpdateVendorStoreParams params,
  ) async {
    // بدون label لتقليل حجم JSON (السيرفر يعيد التسميات)
    final hoursPayload = params.workingHours
        .map((e) => {
              'day_key': e.dayKey,
              'open': e.open,
              'close': e.close,
              'is_closed': e.isClosed,
            })
        .toList();
    final map = <String, dynamic>{
      'category_id': params.categoryId,
      'name': params.name,
      'address': params.address,
      'phone': params.phone,
      'lat': params.lat.toStringAsFixed(7),
      'lng': params.lng.toStringAsFixed(7),
      'working_hours': jsonEncode(hoursPayload),
      'pay_on_delivery': params.payOnDelivery ? 1 : 0,
      'pay_wallet': params.payWallet ? 1 : 0,
      if (params.walletNumber != null) 'wallet_number': params.walletNumber,
      if (params.walletOwnerName != null)
        'wallet_owner_name': params.walletOwnerName,
      if (params.walletType != null) 'wallet_type': params.walletType,
      'listing_kind': params.listingKind,
    };
    if (params.imagePath != null && params.imagePath!.isNotEmpty) {
      map['image'] = await MultipartFile.fromFile(params.imagePath!);
    }
    return map;
  }

  @override
  Future<List<VendorProduct>> fetchProducts() async {
    try {
      var response = await dio.get(vendorProductsEP, options: _auth);
      if (response.statusCode == 404) {
        response = await dio.get(merchantProductsEP, options: _auth);
      }
      if (response.statusCode != 200) {
        throw ServerException(_msg(response.data, 'تعذر تحميل المنتجات'),
            statusCode: response.statusCode);
      }
      return _parseProducts(response.data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        final fallback = await dio.get(merchantProductsEP, options: _auth);
        if (fallback.statusCode == 200) return _parseProducts(fallback.data);
      }
      throw _mapDio(e, 'تعذر تحميل المنتجات');
    }
  }

  @override
  Future<VendorProduct> createProduct(CreateVendorProductParams params) async {
    try {
      final map = <String, dynamic>{
        'name': params.name,
        'price': params.price,
        'is_active': 1,
        if (params.description != null) 'description': params.description,
        'image': await MultipartFile.fromFile(params.imagePath),
      };
      var response = await dio.post(
        vendorProductsEP,
        data: FormData.fromMap(map),
        options: _auth.copyWith(contentType: 'multipart/form-data'),
      );
      if (response.statusCode == 404) {
        response = await dio.post(
          merchantProductsEP,
          data: FormData.fromMap(map),
          options: _auth.copyWith(contentType: 'multipart/form-data'),
        );
      }
      if (response.statusCode != 200 && response.statusCode != 201) {
        throw ServerException(_msg(response.data, 'تعذر إضافة المنتج'),
            statusCode: response.statusCode);
      }
      final data = _extractMap(response.data);
      return VendorProductModel.fromJson(data);
    } on DioException catch (e) {
      throw _mapDio(e, 'تعذر إضافة المنتج');
    }
  }

  @override
  Future<VendorProduct> updateProduct(UpdateVendorProductParams params) async {
    try {
      final map = <String, dynamic>{
        'name': params.name,
        'price': params.price,
        if (params.description != null) 'description': params.description,
      };
      if (params.imagePath != null && params.imagePath!.isNotEmpty) {
        map['image'] = await MultipartFile.fromFile(params.imagePath!);
      }
      final response = await dio.post(
        vendorProductEP(params.productId),
        data: FormData.fromMap(map),
        options: _auth.copyWith(contentType: 'multipart/form-data'),
      );
      if (response.statusCode != 200) {
        throw ServerException(_msg(response.data, 'تعذر تحديث المنتج'),
            statusCode: response.statusCode);
      }
      return VendorProductModel.fromJson(_extractMap(response.data));
    } on DioException catch (e) {
      throw _mapDio(e, 'تعذر تحديث المنتج');
    }
  }

  @override
  Future<void> deleteProduct(int productId) async {
    try {
      var response =
          await dio.delete(vendorProductEP(productId), options: _auth);
      if (response.statusCode == 404 || response.statusCode == 405) {
        response = await dio.post(
          vendorProductDeleteEP(productId),
          options: _auth,
        );
      }
      if (response.statusCode != 200) {
        throw ServerException(_msg(response.data, 'تعذر حذف المنتج'),
            statusCode: response.statusCode);
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 404 || e.response?.statusCode == 405) {
        final fallback = await dio.post(
          vendorProductDeleteEP(productId),
          options: _auth,
        );
        if (fallback.statusCode == 200) return;
      }
      throw _mapDio(e, 'تعذر حذف المنتج');
    }
  }

  @override
  Future<VendorProduct> toggleProduct(int productId) async {
    try {
      var response = await dio.post(
        vendorProductToggleEP(productId),
        options: _auth,
      );
      if (response.statusCode == 404) {
        // Legacy: fetch product then update is_active
        final products = await fetchProducts();
        final product = products.firstWhere(
          (p) => p.id == productId,
          orElse: () => throw const ServerException('المنتج غير موجود'),
        );
        response = await dio.post(
          merchantProductEP(productId),
          data: FormData.fromMap({
            'name': product.name,
            'price': product.price,
            'is_active': product.isActive ? 0 : 1,
            if (product.description != null) 'description': product.description,
          }),
          options: _auth.copyWith(contentType: 'multipart/form-data'),
        );
      }
      if (response.statusCode != 200) {
        throw ServerException(_msg(response.data, 'تعذر تحديث حالة المنتج'),
            statusCode: response.statusCode);
      }
      return VendorProductModel.fromJson(_extractMap(response.data));
    } on DioException catch (e) {
      throw _mapDio(e, 'تعذر تحديث حالة المنتج');
    }
  }

  @override
  Future<List<VendorOrder>> fetchOrders() async {
    try {
      var response = await dio.get(vendorOrdersEP, options: _auth);
      if (response.statusCode == 404) {
        response = await dio.get(merchantOrdersEP, options: _auth);
      }
      if (response.statusCode != 200) {
        throw ServerException(_msg(response.data, 'تعذر تحميل الطلبات'),
            statusCode: response.statusCode);
      }
      return _parseOrders(response.data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        final fallback = await dio.get(merchantOrdersEP, options: _auth);
        if (fallback.statusCode == 200) return _parseOrders(fallback.data);
      }
      throw _mapDio(e, 'تعذر تحميل الطلبات');
    }
  }

  @override
  Future<VendorOrder> handleOrder({
    required int orderId,
    required String action,
    String orderType = 'normal',
  }) async {
    try {
      var response = await dio.post(
        vendorOrderHandleEP(orderId),
        data: {
          'action': action,
          'order_type': orderType,
        },
        options: _auth,
      );
      if (response.statusCode == 404) {
        response = await _legacyHandle(orderId, action);
      }
      if (response.statusCode != 200) {
        throw ServerException(_msg(response.data, 'تعذر معالجة الطلب'),
            statusCode: response.statusCode);
      }
      return VendorOrderModel.fromJson(_extractMap(response.data));
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        final fallback = await _legacyHandle(orderId, action);
        if (fallback.statusCode == 200) {
          return VendorOrderModel.fromJson(_extractMap(fallback.data));
        }
      }
      throw _mapDio(e, 'تعذر معالجة الطلب');
    }
  }

  Future<Response> _legacyHandle(int orderId, String action) async {
    if (action == 'complete') {
      return dio.post(
        vendorOrderHandleEP(orderId),
        data: {'action': 'complete'},
        options: _auth,
      );
    }
    final path = switch (action) {
      'accept' => merchantOrderAcceptEP(orderId),
      'reject' => merchantOrderRejectEP(orderId),
      'confirm_payment' => merchantOrderConfirmPaymentEP(orderId),
      'reject_payment' => merchantOrderRejectPaymentEP(orderId),
      _ => merchantOrderAcceptEP(orderId),
    };
    return dio.post(path, options: _auth);
  }

  @override
  Future<VendorOrder> sendCustomOffer(SendCustomOfferParams params) async {
    try {
      final data = <String, dynamic>{
        if (params.totalPrice != null) 'vendor_price': params.totalPrice,
        if (params.totalPrice != null) 'merchant_offer_price': params.totalPrice,
        if (params.totalPrice != null) 'total_price': params.totalPrice,
        if ((params.notes ?? '').trim().isNotEmpty)
          'vendor_notes': params.notes!.trim(),
        if ((params.notes ?? '').trim().isNotEmpty)
          'merchant_offer_notes': params.notes!.trim(),
        if ((params.notes ?? '').trim().isNotEmpty)
          'offer_notes': params.notes!.trim(),
      };

      var response = await dio.post(
        vendorCustomOrderOfferEP(params.orderId),
        data: data,
        options: _auth,
      );

      if (response.statusCode == 404 || response.statusCode == 405) {
        response = await dio.post(
          merchantOrderSendOfferEP(params.orderId),
          data: {
            if (params.totalPrice != null)
              'merchant_offer_price': params.totalPrice,
            if ((params.notes ?? '').trim().isNotEmpty)
              'merchant_offer_notes': params.notes!.trim(),
          },
          options: _auth,
        );
      }

      if (response.statusCode != 200) {
        throw ServerException(
          _msg(response.data, 'تعذر إرسال العرض'),
          statusCode: response.statusCode,
        );
      }
      return VendorOrderModel.fromJson(_extractMap(response.data));
    } on DioException catch (e) {
      throw _mapDio(e, 'تعذر إرسال العرض');
    }
  }

  @override
  Future<VendorWallet> fetchWallet() async {
    try {
      var response = await dio.get(
        vendorWalletEP,
        queryParameters: {
          't': DateTime.now().millisecondsSinceEpoch,
        },
        options: _auth,
      );
      if (response.statusCode == 404) {
        response = await dio.get(merchantDuesEP, options: _auth);
      }
      if (response.statusCode != 200) {
        throw ServerException(_msg(response.data, 'تعذر تحميل المستحقات'),
            statusCode: response.statusCode);
      }
      return VendorWalletModel.fromJson(_extractMap(response.data));
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        final fallback = await dio.get(merchantDuesEP, options: _auth);
        if (fallback.statusCode == 200) {
          return VendorWalletModel.fromJson(_extractMap(fallback.data));
        }
      }
      throw _mapDio(e, 'تعذر تحميل المستحقات');
    }
  }

  @override
  Future<VendorWallet> updateBillingMode(String billingMode) async {
    try {
      final response = await dio.post(
        vendorWalletBillingModeEP,
        data: {'billing_mode': billingMode},
        options: _auth,
      );
      if (response.statusCode != 200) {
        throw ServerException(
          _msg(response.data, 'تعذر تحديث طريقة الفوترة'),
          statusCode: response.statusCode,
        );
      }
      return VendorWalletModel.fromJson(_extractMap(response.data));
    } on DioException catch (e) {
      throw _mapDio(e, 'تعذر تحديث طريقة الفوترة');
    }
  }

  @override
  Future<void> settleWallet({
    required File receipt,
    required double amount,
  }) async {
    try {
      final ext = receipt.path.split('.').last.toLowerCase();
      final safe = ['jpg', 'jpeg', 'png', 'webp'].contains(ext) ? ext : 'jpg';
      final file = await MultipartFile.fromFile(
        receipt.path,
        filename: 'settle_${DateTime.now().millisecondsSinceEpoch}.$safe',
      );
      var response = await dio.post(
        vendorWalletSettleEP,
        data: FormData.fromMap({
          'amount': amount,
          'receipt_image': file,
          'payment_proof': await MultipartFile.fromFile(
            receipt.path,
            filename: 'settle_${DateTime.now().millisecondsSinceEpoch}.$safe',
          ),
        }),
        options: _auth.copyWith(contentType: 'multipart/form-data'),
      );
      if (response.statusCode == 404) {
        response = await dio.post(
          merchantSettlementEP,
          data: FormData.fromMap({
            'payment_proof': await MultipartFile.fromFile(receipt.path),
            'amount': amount,
          }),
          options: _auth.copyWith(contentType: 'multipart/form-data'),
        );
      }
      if (response.statusCode != 200 && response.statusCode != 201) {
        throw ServerException(_msg(response.data, 'تعذر إرسال طلب السداد'),
            statusCode: response.statusCode);
      }
    } on DioException catch (e) {
      throw _mapDio(e, 'تعذر إرسال طلب السداد');
    }
  }

  Future<VendorStore> _withFallbackCategories(VendorStore store) async {
    if (store.categories.isNotEmpty) return store;
    try {
      var cats = <VendorCategory>[];
      for (final url in [
        localServiceCategoriesEP,
        servicesCategoriesEP,
        vendorStoreProfileEP,
      ]) {
        final res = await dio.get(url, options: _auth);
        if (res.statusCode != 200) continue;
        cats = _categoriesFrom(res.data);
        if (cats.isNotEmpty) break;
      }
      if (cats.isEmpty) return store;
      return VendorStoreModel(
        id: store.id,
        categoryId: store.categoryId,
        name: store.name,
        image: store.image,
        address: store.address,
        phone: store.phone,
        lat: store.lat,
        lng: store.lng,
        workingHours: store.workingHours,
        payOnDelivery: store.payOnDelivery,
        payWallet: store.payWallet,
        walletNumber: store.walletNumber,
        walletOwnerName: store.walletOwnerName,
        walletType: store.walletType,
        listingKind: store.listingKind,
        categories: cats,
      );
    } catch (_) {
      return store;
    }
  }

  List<VendorCategory> _categoriesFrom(dynamic data) {
    List raw = const [];
    void take(dynamic v) {
      if (v is List && v.isNotEmpty) raw = v;
    }

    if (data is Map) {
      take(data['categories']);
      take(data['data']);
      final nested = data['data'];
      if (nested is Map) {
        take(nested['categories']);
        final merchant = nested['merchant'];
        if (merchant is Map) take(merchant['categories']);
      }
    } else if (data is List) {
      raw = data;
    }
    return raw
        .whereType<Map>()
        .map((e) => VendorCategoryModel.fromJson(Map<String, dynamic>.from(e)))
        .where((c) => c.id > 0 && c.name.trim().isNotEmpty)
        .toList();
  }

  VendorStore _parseStore(
    dynamic data, {
    Map<String, dynamic>? paymentOverride,
  }) {
    final root = data is Map ? Map<String, dynamic>.from(data) : <String, dynamic>{};
    final nested = root['data'] is Map
        ? Map<String, dynamic>.from(root['data'] as Map)
        : root;
    final merchant = nested['merchant'] is Map
        ? Map<String, dynamic>.from(nested['merchant'] as Map)
        : nested;
    var rawCategories = nested['categories'];
    if (rawCategories is! List) {
      rawCategories = root['categories'];
    }
    if (rawCategories is! List && merchant['categories'] is List) {
      rawCategories = merchant['categories'];
    }
    final categories = (rawCategories is List ? rawCategories : const [])
        .whereType<Map>()
        .map((e) => VendorCategoryModel.fromJson(Map<String, dynamic>.from(e)))
        .where((c) => c.id > 0 && c.name.trim().isNotEmpty)
        .toList();
    final payment = paymentOverride ??
        (nested['payment'] is Map
            ? Map<String, dynamic>.from(nested['payment'] as Map)
            : merchant);

    final hubRaw = (nested['vendor_hub_section'] ??
            merchant['category_hub_section'] ??
            '')
        .toString()
        .trim()
        .toLowerCase();
    final hasCategory = merchant['category_id'] != null;
    if (hasCategory &&
        (hubRaw == 'orders' ||
            hubRaw == 'bookings' ||
            hubRaw == 'services')) {
      AuthPrefs.saveVendorHubSection(hubRaw);
    }

    return VendorStoreModel.fromJson(
      merchant,
      categories: categories,
      payment: payment,
    );
  }

  List<VendorProduct> _parseProducts(dynamic data) {
    final nested = data is Map ? (data['data'] ?? data) : data;
    List list;
    if (nested is Map && nested['products'] is List) {
      list = nested['products'] as List;
    } else if (nested is List) {
      list = nested;
    } else {
      list = const [];
    }
    return list
        .whereType<Map>()
        .map((e) => VendorProductModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  List<VendorOrder> _parseOrders(dynamic data) {
    final nested = data is Map ? (data['data'] ?? data) : data;
    List list;
    if (nested is Map && nested['orders'] is List) {
      list = nested['orders'] as List;
    } else if (nested is List) {
      list = nested;
    } else {
      list = const [];
    }
    return list
        .whereType<Map>()
        .map((e) => VendorOrderModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Map<String, dynamic> _extractMap(dynamic data) {
    if (data is Map) {
      final map = Map<String, dynamic>.from(data);
      final nested = map['data'];
      if (nested is Map) return Map<String, dynamic>.from(nested);
      return map;
    }
    throw const ServerException('استجابة غير متوقعة من السيرفر');
  }

  String _msg(dynamic data, String fallback) {
    if (data is Map && data['message'] is String) {
      final m = (data['message'] as String).trim();
      if (m.isEmpty) return fallback;
      // لا نعرض SQL الخام للمستخدم
      if (m.contains('SQLSTATE') ||
          m.contains('INSERT INTO') ||
          m.contains('UPDATE ') ||
          m.length > 180) {
        return fallback;
      }
      return m;
    }
    if (data is String) {
      final m = data.trim();
      if (m.contains('SQLSTATE') || m.contains('INSERT INTO') || m.length > 180) {
        return fallback;
      }
      if (m.isNotEmpty) return m;
    }
    return fallback;
  }

  Exception _mapDio(DioException e, String fallback) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.connectionError) {
      return const NetworkException();
    }
    if (e.response != null) {
      return ServerException(
        _msg(e.response?.data, fallback),
        statusCode: e.response?.statusCode,
      );
    }
    return NetworkException(e.message ?? fallback);
  }
}
