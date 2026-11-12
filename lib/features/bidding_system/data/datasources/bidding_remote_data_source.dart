import 'package:dio/dio.dart';
import 'package:motorent/data/local/cache_helper.dart';
import 'package:motorent/data/remote/url_api.dart';
import 'package:motorent/features/bidding_system/core/error/exceptions.dart';
import 'package:motorent/features/bidding_system/data/models/bidding_offer_model.dart';
import 'package:motorent/features/bidding_system/data/models/bidding_trip_model.dart';
import 'package:motorent/features/bidding_system/domain/entities/create_bidding_trip_params.dart';

abstract class BiddingRemoteDataSource {
  Future<BiddingTripModel> createTrip(CreateBiddingTripParams params);

  Future<List<BiddingOfferModel>> fetchOffers(int tripId);

  Future<BiddingTripModel> acceptOffer(int offerId);

  Future<BiddingTripModel> fetchTrip(int tripId);

  Future<List<BiddingTripModel>> getMyTrips();

  Future<BiddingTripModel> getTripDetails(int tripId);

  Future<BiddingTripModel> cancelTrip(int tripId);
}

class BiddingRemoteDataSourceImpl implements BiddingRemoteDataSource {
  final Dio dio;

  BiddingRemoteDataSourceImpl({Dio? dio}) : dio = dio ?? Dio();

  Options get _authOptions => Options(
        headers: {
          'Authorization': 'Bearer ${CacheHelper.getData(key: 'token')}',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        sendTimeout: const Duration(seconds: 25),
        receiveTimeout: const Duration(seconds: 25),
        validateStatus: (status) => status != null && status < 600,
      );

  @override
  Future<BiddingTripModel> createTrip(CreateBiddingTripParams params) async {
    try {
      final response = await dio.post(
        biddingTripsCreateEP,
        data: params.toJson(),
        options: _authOptions,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return BiddingTripModel.fromJson(_extractMap(response.data));
      }

      throw ServerException(
        _messageFrom(response.data, fallback: 'تعذر إنشاء الطلب'),
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      throw _mapDio(e, 'تعذر إنشاء الطلب');
    }
  }

  @override
  Future<List<BiddingOfferModel>> fetchOffers(int tripId) async {
    try {
      final response = await dio.get(
        biddingTripOffersEP(tripId),
        options: _authOptions,
      );

      if (response.statusCode == 200) {
        final list = _extractList(response.data);
        return list
            .whereType<Map>()
            .map((e) => BiddingOfferModel.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      }

      throw ServerException(
        _messageFrom(response.data, fallback: 'تعذر تحميل العروض'),
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      throw _mapDio(e, 'تعذر تحميل العروض');
    }
  }

  @override
  Future<BiddingTripModel> acceptOffer(int offerId) async {
    try {
      final response = await dio.post(
        biddingOfferAcceptEP(offerId),
        options: _authOptions,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return BiddingTripModel.fromJson(_extractMap(response.data));
      }

      throw ServerException(
        _messageFrom(response.data, fallback: 'تعذر قبول العرض'),
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      throw _mapDio(e, 'تعذر قبول العرض');
    }
  }

  @override
  Future<BiddingTripModel> fetchTrip(int tripId) async {
    try {
      Response response = await dio.get(
        biddingTripDetailEP(tripId),
        options: _authOptions,
      );

      if (response.statusCode == 404) {
        response = await dio.get(
          biddingTripDetailsEP(tripId),
          options: _authOptions,
        );
      }

      if (response.statusCode == 200) {
        return BiddingTripModel.fromJson(_extractMap(response.data));
      }

      throw ServerException(
        _messageFrom(response.data, fallback: 'تعذر تحميل تفاصيل الرحلة'),
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      throw _mapDio(e, 'تعذر تحميل تفاصيل الرحلة');
    }
  }

  @override
  Future<List<BiddingTripModel>> getMyTrips() async {
    try {
      final response = await dio.get(
        biddingMyTripsEP,
        options: _authOptions,
      );

      if (response.statusCode == 200) {
        final list = _extractList(response.data, keys: const ['data', 'trips']);
        return list
            .whereType<Map>()
            .map((e) => BiddingTripModel.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      }

      throw ServerException(
        _messageFrom(response.data, fallback: 'تعذر تحميل الطلبات'),
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      throw _mapDio(e, 'تعذر تحميل الطلبات');
    }
  }

  @override
  Future<BiddingTripModel> getTripDetails(int tripId) async {
    try {
      final response = await dio.get(
        biddingTripDetailsEP(tripId),
        options: _authOptions,
      );

      if (response.statusCode == 200) {
        return BiddingTripModel.fromJson(_extractMap(response.data));
      }

      throw ServerException(
        _messageFrom(response.data, fallback: 'تعذر تحميل تفاصيل الطلب'),
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      throw _mapDio(e, 'تعذر تحميل تفاصيل الطلب');
    }
  }

  @override
  Future<BiddingTripModel> cancelTrip(int tripId) async {
    try {
      final response = await dio.post(
        biddingTripCancelEP(tripId),
        options: _authOptions,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final map = _tryExtractMap(response.data);
        if (map != null && map.containsKey('id')) {
          return BiddingTripModel.fromJson(map);
        }
        // Some APIs only return a success message — synthesize cancelled trip.
        return BiddingTripModel(
          id: tripId,
          userId: 0,
          vehicleType: '',
          pickupAddress: '',
          dropoffAddress: '',
          description: '',
          phone: '',
          status: 'cancelled',
        );
      }

      throw ServerException(
        _messageFrom(response.data, fallback: 'تعذر إلغاء الطلب'),
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      throw _mapDio(e, 'تعذر إلغاء الطلب');
    }
  }

  Map<String, dynamic> _extractMap(dynamic data) {
    final map = _tryExtractMap(data);
    if (map != null) return map;
    throw const ServerException('استجابة غير متوقعة من السيرفر');
  }

  Map<String, dynamic>? _tryExtractMap(dynamic data) {
    if (data is Map) {
      final map = Map<String, dynamic>.from(data);
      final nested = map['data'] ?? map['trip'] ?? map['message'];
      if (nested is Map) {
        return Map<String, dynamic>.from(nested);
      }
      return map;
    }
    return null;
  }

  List<dynamic> _extractList(
    dynamic data, {
    List<String> keys = const ['data', 'offers'],
  }) {
    if (data is List) return data;
    if (data is Map) {
      for (final key in keys) {
        final nested = data[key];
        if (nested is List) return nested;
      }
    }
    return const [];
  }

  String _messageFrom(dynamic data, {required String fallback}) {
    if (data is Map) {
      final message = data['message']?.toString();
      if (message != null && message.trim().isNotEmpty) {
        return message;
      }
      final errors = data['errors'];
      if (errors is Map && errors.isNotEmpty) {
        final first = errors.values.first;
        if (first is List && first.isNotEmpty) {
          return first.first.toString();
        }
      }
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
        _messageFrom(e.response?.data, fallback: fallback),
        statusCode: e.response?.statusCode,
      );
    }

    return NetworkException(e.message ?? fallback);
  }
}
