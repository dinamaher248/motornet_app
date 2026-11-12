import 'package:dio/dio.dart';
import 'package:motorent/data/local/cache_helper.dart';
import 'package:motorent/data/remote/url_api.dart';
import 'package:motorent/features/services/core/error/exceptions.dart';
import 'package:motorent/features/services/data/models/service_models.dart';
import 'package:motorent/features/services/domain/entities/service_entities.dart';

abstract class ServiceRemoteDataSource {
  Future<List<Store>> fetchStores({
    required String category,
    double? lat,
    double? lng,
    String? listingKind,
  });

  Future<Store> fetchStoreDetails(int id, {double? lat, double? lng});

  Future<ServiceOrder> checkout(CheckoutParams params);

  Future<CustomOrder> submitCustomOrder(SubmitCustomOrderParams params);

  Future<CustomOrder> respondToCustomOffer({
    required int orderId,
    required String action,
  });
}

class ServiceRemoteDataSourceImpl implements ServiceRemoteDataSource {
  final Dio dio;

  ServiceRemoteDataSourceImpl({Dio? dio}) : dio = dio ?? Dio();

  Options get _authOptions => Options(
        headers: {
          'Authorization': 'Bearer ${CacheHelper.getData(key: 'token')}',
          'Accept': 'application/json',
        },
        sendTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        validateStatus: (status) => status != null && status < 600,
      );

  @override
  Future<List<Store>> fetchStores({
    required String category,
    double? lat,
    double? lng,
    String? listingKind,
  }) async {
    try {
      final response = await dio.get(
        servicesStoresEP,
        queryParameters: {
          'category': category,
          if (lat != null) 'lat': lat,
          if (lng != null) 'lng': lng,
          if (listingKind != null && listingKind.isNotEmpty)
            'listing_kind': listingKind,
        },
        options: _authOptions,
      );

      if (response.statusCode != 200) {
        // Fallback to legacy local-services endpoint
        return _fetchStoresLegacy(
          category,
          lat: lat,
          lng: lng,
          listingKind: listingKind,
        );
      }

      final list = _extractList(response.data);
      return list
          .whereType<Map>()
          .map((e) => StoreModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return _fetchStoresLegacy(
          category,
          lat: lat,
          lng: lng,
          listingKind: listingKind,
        );
      }
      throw _mapDio(e, 'تعذر تحميل المتاجر');
    }
  }

  Future<List<Store>> _fetchStoresLegacy(
    String category, {
    double? lat,
    double? lng,
    String? listingKind,
  }) async {
    final response = await dio.get(
      localServiceMerchantsEP(category),
      queryParameters: {
        if (lat != null) 'lat': lat,
        if (lng != null) 'lng': lng,
        if (listingKind != null && listingKind.isNotEmpty)
          'listing_kind': listingKind,
      },
      options: _authOptions,
    );
    if (response.statusCode != 200) {
      throw ServerException(
        _message(response.data, 'تعذر تحميل المتاجر'),
        statusCode: response.statusCode,
      );
    }
    final list = _extractList(response.data);
    return list
        .whereType<Map>()
        .map((e) => StoreModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  @override
  Future<Store> fetchStoreDetails(
    int id, {
    double? lat,
    double? lng,
  }) async {
    try {
      final response = await dio.get(
        servicesStoreDetailEP(id),
        queryParameters: {
          if (lat != null) 'lat': lat,
          if (lng != null) 'lng': lng,
        },
        options: _authOptions,
      );

      if (response.statusCode != 200) {
        return _fetchStoreLegacy(id, lat: lat, lng: lng);
      }

      return StoreModel.fromJson(_extractMap(response.data));
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return _fetchStoreLegacy(id, lat: lat, lng: lng);
      }
      throw _mapDio(e, 'تعذر تحميل تفاصيل المتجر');
    }
  }

  Future<Store> _fetchStoreLegacy(
    int id, {
    double? lat,
    double? lng,
  }) async {
    final response = await dio.get(
      localServiceMerchantEP(id),
      queryParameters: {
        if (lat != null) 'lat': lat,
        if (lng != null) 'lng': lng,
      },
      options: _authOptions,
    );
    if (response.statusCode != 200) {
      throw ServerException(
        _message(response.data, 'تعذر تحميل تفاصيل المتجر'),
        statusCode: response.statusCode,
      );
    }
    return StoreModel.fromJson(_extractMap(response.data));
  }

  @override
  Future<ServiceOrder> checkout(CheckoutParams params) async {
    try {
      final map = <String, dynamic>{
        'store_id': params.storeId,
        'merchant_id': params.storeId,
        'product_id': params.productId,
        'quantity': params.quantity,
        'product_total': params.productTotal,
        'notes': params.notes,
        'delivery_address': params.deliveryAddress,
        if (params.deliveryLat != null) 'delivery_lat': params.deliveryLat,
        if (params.deliveryLng != null) 'delivery_lng': params.deliveryLng,
        'payment_method': params.paymentMethod,
        'fulfillment_type': params.fulfillmentType,
      };

      if (params.walletReceiptPath != null &&
          params.walletReceiptPath!.isNotEmpty) {
        final path = params.walletReceiptPath!;
        final ext = path.split('.').last.toLowerCase();
        final safe = ['jpg', 'jpeg', 'png', 'webp'].contains(ext) ? ext : 'jpg';
        final file = await MultipartFile.fromFile(
          path,
          filename: 'receipt_${DateTime.now().millisecondsSinceEpoch}.$safe',
        );
        map['wallet_receipt'] = file;
        map['payment_proof'] = await MultipartFile.fromFile(
          path,
          filename: 'receipt_${DateTime.now().millisecondsSinceEpoch}.$safe',
        );
      }

      var response = await dio.post(
        servicesCheckoutEP,
        data: FormData.fromMap(map),
        options: _authOptions.copyWith(contentType: 'multipart/form-data'),
      );

      if (response.statusCode == 404 || response.statusCode == 405) {
        response = await dio.post(
          localServiceOrdersEP,
          data: FormData.fromMap(map),
          options: _authOptions.copyWith(contentType: 'multipart/form-data'),
        );
      }

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw ServerException(
          _message(response.data, 'تعذر إرسال الطلب'),
          statusCode: response.statusCode,
        );
      }

      final data = response.data;
      if (data is Map) {
        final nested = data['data'] ?? data['order'] ?? data;
        if (nested is Map) {
          final order = ServiceOrderModel.fromJson(
            Map<String, dynamic>.from(nested),
          );
          return ServiceOrder(
            id: order.id,
            status: order.status,
            message: (data['message'] is String)
                ? data['message'] as String
                : order.message,
          );
        }
      }

      return const ServiceOrder(
        id: 0,
        status: 'pending',
        message: 'تم إرسال الطلب للمتجر وهو بانتظار المراجعة',
      );
    } on DioException catch (e) {
      throw _mapDio(e, 'تعذر إرسال الطلب');
    }
  }

  @override
  Future<CustomOrder> submitCustomOrder(SubmitCustomOrderParams params) async {
    try {
      final map = <String, dynamic>{
        'store_id': params.storeId,
        'merchant_id': params.storeId,
        'customer_contact_phone': params.contactPhone,
        'delivery_address': params.deliveryAddress,
        if (params.hasText) 'custom_request_text': params.requestText!.trim(),
        if (params.deliveryLat != null) 'delivery_lat': params.deliveryLat,
        if (params.deliveryLng != null) 'delivery_lng': params.deliveryLng,
        if ((params.notes ?? '').trim().isNotEmpty) 'notes': params.notes!.trim(),
      };

      if (params.hasImage) {
        final path = params.requestImagePath!;
        final ext = path.split('.').last.toLowerCase();
        final safe = ['jpg', 'jpeg', 'png', 'webp'].contains(ext) ? ext : 'jpg';
        map['custom_request_image'] = await MultipartFile.fromFile(
          path,
          filename:
              'custom_${DateTime.now().millisecondsSinceEpoch}.$safe',
        );
      }

      var response = await dio.post(
        servicesCustomOrdersSubmitEP,
        data: FormData.fromMap(map),
        options: _authOptions.copyWith(contentType: 'multipart/form-data'),
      );

      if (response.statusCode == 404 || response.statusCode == 405) {
        response = await dio.post(
          localServiceCustomOrdersEP,
          data: FormData.fromMap(map),
          options: _authOptions.copyWith(contentType: 'multipart/form-data'),
        );
      }

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw ServerException(
          _message(response.data, 'تعذر إرسال الطلب المخصص'),
          statusCode: response.statusCode,
        );
      }

      return _parseCustomOrder(response.data);
    } on DioException catch (e) {
      throw _mapDio(e, 'تعذر إرسال الطلب المخصص');
    }
  }

  @override
  Future<CustomOrder> respondToCustomOffer({
    required int orderId,
    required String action,
  }) async {
    try {
      var response = await dio.post(
        servicesCustomOrderRespondEP(orderId),
        data: {'action': action},
        options: _authOptions,
      );

      if (response.statusCode == 404 || response.statusCode == 405) {
        final legacy = action == 'reject'
            ? localServiceRejectOfferEP(orderId)
            : localServiceAcceptOfferEP(orderId);
        response = await dio.post(legacy, options: _authOptions);
      }

      if (response.statusCode != 200) {
        throw ServerException(
          _message(response.data, 'تعذر الرد على العرض'),
          statusCode: response.statusCode,
        );
      }

      return _parseCustomOrder(response.data);
    } on DioException catch (e) {
      throw _mapDio(e, 'تعذر الرد على العرض');
    }
  }

  CustomOrder _parseCustomOrder(dynamic data) {
    final map = _extractOrderMap(data);
    final order = CustomOrderModel.fromJson(map);
    final msg = data is Map && data['message'] is String
        ? data['message'] as String
        : order.message;
    return CustomOrder(
      id: order.id,
      orderType: order.orderType,
      storeId: order.storeId,
      storeName: order.storeName,
      requestText: order.requestText,
      requestImage: order.requestImage,
      deliveryAddress: order.deliveryAddress,
      contactPhone: order.contactPhone,
      notes: order.notes,
      offerPrice: order.offerPrice,
      offerNotes: order.offerNotes,
      status: order.status,
      statusLabel: order.statusLabel,
      canAcceptOffer: order.canAcceptOffer,
      canRejectOffer: order.canRejectOffer,
      message: msg,
    );
  }

  Map<String, dynamic> _extractOrderMap(dynamic data) {
    if (data is Map) {
      final map = Map<String, dynamic>.from(data);
      final nested = map['data'] ?? map['order'];
      if (nested is Map) return Map<String, dynamic>.from(nested);
      return map;
    }
    throw const ServerException('استجابة غير متوقعة من السيرفر');
  }

  Map<String, dynamic> _extractMap(dynamic data) {
    if (data is Map) {
      final map = Map<String, dynamic>.from(data);
      final nested = map['data'] ?? map['store'] ?? map['merchant'];
      if (nested is Map) return Map<String, dynamic>.from(nested);
      return map;
    }
    throw const ServerException('استجابة غير متوقعة من السيرفر');
  }

  List<dynamic> _extractList(dynamic data) {
    if (data is List) return data;
    if (data is Map) {
      final nested = data['data'] ?? data['stores'];
      if (nested is List) return nested;
    }
    return const [];
  }

  String _message(dynamic data, String fallback) {
    if (data is Map) {
      final message = data['message'];
      if (message is String && message.trim().isNotEmpty) return message;
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
        _message(e.response?.data, fallback),
        statusCode: e.response?.statusCode,
      );
    }
    return NetworkException(e.message ?? fallback);
  }
}
