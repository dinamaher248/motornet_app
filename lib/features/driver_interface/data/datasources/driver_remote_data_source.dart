import 'dart:io';

import 'package:dio/dio.dart';
import 'package:motorent/data/local/cache_helper.dart';
import 'package:motorent/data/remote/url_api.dart';
import 'package:motorent/features/driver_interface/core/error/exceptions.dart';
import 'package:motorent/features/driver_interface/data/models/driver_models.dart';
import 'package:motorent/features/driver_interface/domain/entities/driver_entities.dart';
import 'package:motorent/services/driver_location_sync.dart';

abstract class DriverRemoteDataSource {
  Future<bool> toggleOnline(bool online);

  Future<List<DriverTrip>> fetchAvailableBids();

  Future<bool> makeOffer({
    required int tripId,
    required String type,
    required double amount,
  });

  Future<void> declineTrip({
    required int tripId,
    required String type,
  });

  Future<List<DriverTrip>> fetchMyTrips();

  Future<DriverWallet> fetchWallet();

  Future<DriverWallet> updateBillingMode(String billingMode);

  Future<void> settleWallet({
    required File receipt,
    required double amount,
  });
}

class DriverRemoteDataSourceImpl implements DriverRemoteDataSource {
  final Dio dio;

  DriverRemoteDataSourceImpl({Dio? dio}) : dio = dio ?? Dio();

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
  Future<bool> toggleOnline(bool online) async {
    try {
      final coords = online ? await DriverLocationSync.currentCoords() : null;
      final response = await dio.post(
        toggleOnlineEP,
        data: {
          'is_online': online ? 1 : 0,
          if (coords != null) 'lat': coords['lat'],
          if (coords != null) 'lng': coords['lng'],
          if (coords != null) 'current_lat': coords['lat'],
          if (coords != null) 'current_lng': coords['lng'],
        },
        options: _authOptions,
      );
      if (response.statusCode != 200) {
        throw ServerException(
          _message(response.data, 'تعذر تحديث حالة التوفر'),
          statusCode: response.statusCode,
        );
      }
      await CacheHelper.saveData(key: 'is_online', value: online ? 1 : 0);
      if (online) {
        // Fire-and-forget location refresh for radius matching.
        // ignore: unawaited_futures
        DriverLocationSync.syncNow(force: true);
      }
      return online;
    } on DioException catch (e) {
      throw _mapDio(e, 'تعذر تحديث حالة التوفر');
    }
  }

  @override
  Future<List<DriverTrip>> fetchAvailableBids() async {
    try {
      // Keep driver GPS fresh so nearby radius filtering works.
      await DriverLocationSync.syncNow();
      final coords = await DriverLocationSync.currentCoords();
      var response = await dio.get(
        driverAvailableBidsEP,
        queryParameters: {
          if (coords != null) 'lat': coords['lat'],
          if (coords != null) 'lng': coords['lng'],
        },
        options: _authOptions,
      );
      if (response.statusCode == 404) {
        response =
            await dio.get(driverAvailableOrdersEP, options: _authOptions);
      }
      if (response.statusCode != 200) {
        throw ServerException(
          _message(response.data, 'تعذر تحميل الطلبات المتاحة'),
          statusCode: response.statusCode,
        );
      }
      return _parseTrips(response.data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        final fallback =
            await dio.get(driverAvailableOrdersEP, options: _authOptions);
        if (fallback.statusCode == 200) return _parseTrips(fallback.data);
      }
      throw _mapDio(e, 'تعذر تحميل الطلبات المتاحة');
    }
  }

  @override
  Future<void> declineTrip({
    required int tripId,
    required String type,
  }) async {
    try {
      final response = await dio.post(
        driverDeclineTripEP(tripId),
        data: {'type': type},
        options: _authOptions,
      );
      if (response.statusCode != 200 && response.statusCode != 201) {
        throw ServerException(
          _message(response.data, 'تعذر رفض الطلب'),
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      throw _mapDio(e, 'تعذر رفض الطلب');
    }
  }

  @override
  Future<bool> makeOffer({
    required int tripId,
    required String type,
    required double amount,
  }) async {
    try {
      var response = await dio.post(
        driverMakeOfferEP(tripId),
        data: {
          'price': amount,
          'amount': amount,
          'proposed_price': amount,
          'type': type,
        },
        options: _authOptions,
      );

      if (response.statusCode == 404) {
        response = await _legacyMakeOffer(tripId, type, amount);
      }

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw ServerException(
          _message(response.data, 'تعذر إرسال العرض'),
          statusCode: response.statusCode,
        );
      }
      return _tripStartedFrom(response.data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        final fallback = await _legacyMakeOffer(tripId, type, amount);
        if (fallback.statusCode == 200 || fallback.statusCode == 201) {
          return _tripStartedFrom(fallback.data);
        }
      }
      throw _mapDio(e, 'تعذر إرسال العرض');
    }
  }

  Future<Response> _legacyMakeOffer(
    int tripId,
    String type,
    double amount,
  ) async {
    if (type == 'service_order') {
      return dio.post(
        localServiceDeliveryOfferEP(tripId),
        data: {'amount': amount},
        options: _authOptions,
      );
    }
    if (type == 'bidding_trip') {
      return dio.post(
        driverMakeOfferEP(tripId),
        data: {'price': amount, 'proposed_price': amount, 'amount': amount},
        options: _authOptions,
      );
    }
    return dio.post(
      tripRequestSubmitOfferEP(tripId),
      data: {'amount': amount},
      options: _authOptions,
    );
  }

  @override
  Future<List<DriverTrip>> fetchMyTrips() async {
    try {
      var response = await dio.get(driverMyTripsEP, options: _authOptions);
      if (response.statusCode == 404) {
        response = await dio.get(driverMyOrdersEP, options: _authOptions);
      }
      if (response.statusCode != 200) {
        throw ServerException(
          _message(response.data, 'تعذر تحميل طلباتك'),
          statusCode: response.statusCode,
        );
      }
      return _parseTrips(response.data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        final fallback = await dio.get(driverMyOrdersEP, options: _authOptions);
        if (fallback.statusCode == 200) return _parseTrips(fallback.data);
      }
      throw _mapDio(e, 'تعذر تحميل طلباتك');
    }
  }

  @override
  Future<DriverWallet> fetchWallet() async {
    try {
      var response = await dio.get(
        driverWalletEP,
        queryParameters: {
          't': DateTime.now().millisecondsSinceEpoch,
        },
        options: _authOptions,
      );
      if (response.statusCode == 404) {
        response = await dio.get(driverDuesEP, options: _authOptions);
      }
      if (response.statusCode != 200) {
        throw ServerException(
          _message(response.data, 'تعذر تحميل المستحقات'),
          statusCode: response.statusCode,
        );
      }
      return DriverWalletModel.fromJson(_extractMap(response.data));
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        final fallback = await dio.get(driverDuesEP, options: _authOptions);
        if (fallback.statusCode == 200) {
          return DriverWalletModel.fromJson(_extractMap(fallback.data));
        }
      }
      throw _mapDio(e, 'تعذر تحميل المستحقات');
    }
  }

  @override
  @override
  Future<DriverWallet> updateBillingMode(String billingMode) async {
    try {
      final response = await dio.post(
        driverWalletBillingModeEP,
        data: {'billing_mode': billingMode},
        options: _authOptions,
      );
      if (response.statusCode != 200) {
        throw ServerException(
          _message(response.data, 'تعذر تحديث طريقة الفوترة'),
          statusCode: response.statusCode,
        );
      }
      return DriverWalletModel.fromJson(_extractMap(response.data));
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

      final map = <String, dynamic>{
        'amount': amount,
        'receipt_image': file,
        'payment_proof': await MultipartFile.fromFile(
          receipt.path,
          filename: 'settle_${DateTime.now().millisecondsSinceEpoch}.$safe',
        ),
      };

      var response = await dio.post(
        driverWalletSettleEP,
        data: FormData.fromMap(map),
        options: _authOptions.copyWith(contentType: 'multipart/form-data'),
      );

      if (response.statusCode == 404) {
        response = await dio.post(
          driverSettlementEP,
          data: FormData.fromMap({
            'payment_proof': await MultipartFile.fromFile(
              receipt.path,
              filename: 'settle_${DateTime.now().millisecondsSinceEpoch}.$safe',
            ),
            'amount': amount,
          }),
          options: _authOptions.copyWith(contentType: 'multipart/form-data'),
        );
      }

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw ServerException(
          _message(response.data, 'تعذر إرسال طلب السداد'),
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      throw _mapDio(e, 'تعذر إرسال طلب السداد');
    }
  }

  List<DriverTrip> _parseTrips(dynamic data) {
    final list = _extractList(data);
    return list
        .whereType<Map>()
        .map((e) => DriverTripModel.fromJson(Map<String, dynamic>.from(e)))
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

  List<dynamic> _extractList(dynamic data) {
    if (data is List) return data;
    if (data is Map) {
      final nested = data['data'];
      if (nested is List) return nested;
    }
    return const [];
  }

  bool _tripStartedFrom(dynamic data) {
    if (data is! Map) return false;
    final map = Map<String, dynamic>.from(data);
    if (map['trip_started'] == true ||
        map['trip_started'] == 1 ||
        map['trip_started'] == '1') {
      return true;
    }
    final nested = map['data'];
    if (nested is Map) {
      final status = (nested['status'] ?? '').toString();
      if (status == 'in_progress' || status == 'accepted') return true;
    }
    final trip = map['trip'];
    if (trip is Map) {
      final status = (trip['status'] ?? '').toString();
      if (status == 'in_progress') return true;
    }
    return false;
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
