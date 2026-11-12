import 'package:dio/dio.dart';
import 'package:motorent/data/local/cache_helper.dart';
import 'package:motorent/data/remote/url_api.dart';
import 'package:motorent/models/trip_request_models.dart';

class TripRequestService {
  final Dio _dio = Dio();

  Options get _authOptions => Options(
        headers: {
          'Authorization': 'Bearer ${CacheHelper.getData(key: 'token')}',
          'Accept': 'application/json',
        },
        sendTimeout: const Duration(seconds: 20),
        receiveTimeout: const Duration(seconds: 20),
        validateStatus: (status) => status != null && status < 600,
      );

  Future<TripRequestItem> createRequest(Map<String, dynamic> payload) async {
    final response = await _dio.post(
      tripRequestsEP,
      data: payload,
      options: _authOptions,
    );

    if (response.statusCode != 201 || response.data is! Map) {
      throw Exception(_messageFromResponse(response));
    }

    final data = response.data['data'] as Map<String, dynamic>;
    return TripRequestItem.fromJson(data);
  }

  Future<List<TripRequestItem>> fetchMyRequests() async {
    final response = await _dio.get(tripRequestsMineEP, options: _authOptions);
    return _parseTripList(response);
  }

  Future<List<TripRequestItem>> fetchDriverRequests() async {
    final response = await _dio.get(tripRequestsDriverEP, options: _authOptions);
    return _parseTripList(response);
  }

  Future<List<TripOfferItem>> fetchOffers(int tripId) async {
    final response = await _dio.get(
      tripRequestOffersEP(tripId),
      options: _authOptions,
    );

    if (response.statusCode != 200 || response.data is! Map) {
      throw Exception(_messageFromResponse(response));
    }

    final list = response.data['data'] as List<dynamic>? ?? [];
    return list
        .map((e) => TripOfferItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> submitOffer({
    required int tripId,
    required double amount,
  }) async {
    final response = await _dio.post(
      tripRequestSubmitOfferEP(tripId),
      data: {'amount': amount},
      options: _authOptions,
    );

    if (response.statusCode != 200) {
      throw Exception(_messageFromResponse(response));
    }
  }

  Future<void> acceptOffer({
    required int tripId,
    required int offerId,
  }) async {
    final response = await _dio.post(
      tripRequestAcceptOfferEP(tripId, offerId),
      options: _authOptions,
    );

    if (response.statusCode != 200) {
      throw Exception(_messageFromResponse(response));
    }
  }

  Future<TripRequestItem> fetchTripDetail(int id) async {
    final response = await _dio.get(tripRequestEP(id), options: _authOptions);

    if (response.statusCode != 200 || response.data is! Map) {
      throw Exception(_messageFromResponse(response));
    }

    final data = response.data['data'] as Map<String, dynamic>;
    return TripRequestItem.fromJson(data);
  }

  Future<TripRequestItem> cancelTrip(int id) async {
    final response = await _dio.post(
      tripRequestCancelEP(id),
      options: _authOptions,
    );

    if (response.statusCode != 200 || response.data is! Map) {
      throw Exception(_messageFromResponse(response));
    }

    final data = response.data['data'] as Map<String, dynamic>;
    return TripRequestItem.fromJson(data);
  }

  List<TripRequestItem> _parseTripList(Response response) {
    if (response.statusCode != 200 || response.data is! Map) {
      throw Exception(_messageFromResponse(response));
    }

    final list = response.data['data'] as List<dynamic>? ?? [];
    return list
        .map((e) => TripRequestItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  String _messageFromResponse(Response response) {
    final data = response.data;
    if (data is Map && data['message'] != null) {
      return data['message'].toString();
    }
    return 'تعذر إتمام العملية';
  }
}
