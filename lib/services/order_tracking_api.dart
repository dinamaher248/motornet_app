import 'package:dio/dio.dart';
import 'package:motorent/data/local/cache_helper.dart';
import 'package:motorent/data/remote/url_api.dart';
import 'package:motorent/models/order_tracking_models.dart';
import 'package:motorent/services/driver_api.dart';

class OrderTrackingApi {
  final Dio _dio = Dio();

  Options get _auth => Options(
        headers: {
          'Authorization': 'Bearer ${CacheHelper.getData(key: 'token')}',
          'Accept': 'application/json',
        },
        validateStatus: (s) => s != null && s < 600,
      );

  Future<OrderTrackingData> fetch(String type, int id) async {
    final res = await _dio.get(orderTrackingEP(type, id), options: _auth);
    if (res.statusCode != 200 || res.data is! Map) {
      throw Exception(_msg(res.data, 'تعذر تحميل التتبع'));
    }
    final map = Map<String, dynamic>.from(res.data as Map);
    final data = map['data'];
    if (data is! Map) throw Exception('استجابة غير متوقعة');
    return OrderTrackingData.fromJson(Map<String, dynamic>.from(data));
  }

  Future<OrderTrackingData> handToDriver(String type, int id) async {
    final res =
        await _dio.post(orderHandToDriverEP(type, id), options: _auth);
    if (res.statusCode != 200 || res.data is! Map) {
      throw Exception(_msg(res.data, 'تعذر تأكيد التسليم للسائق'));
    }
    final map = Map<String, dynamic>.from(res.data as Map);
    final data = map['data'];
    if (data is! Map) throw Exception('استجابة غير متوقعة');
    return OrderTrackingData.fromJson(Map<String, dynamic>.from(data));
  }

  Future<OrderTrackingData> cancel(String type, int id) async {
    final res =
        await _dio.post(orderTrackingCancelEP(type, id), options: _auth);
    if (res.statusCode != 200 || res.data is! Map) {
      throw Exception(_msg(res.data, 'تعذر إنهاء الطلب'));
    }
    final map = Map<String, dynamic>.from(res.data as Map);
    final data = map['data'];
    if (data is! Map) throw Exception('استجابة غير متوقعة');
    return OrderTrackingData.fromJson(Map<String, dynamic>.from(data));
  }

  Future<void> confirmDelivery(String type, int id) async {
    await DriverApi().completeOrder(type, id);
  }

  Future<OrderTrackingData> updateProgress(
    String type,
    int id, {
    required String action,
  }) async {
    final slug = action == 'picked_up' ? 'picked-up' : 'going-to-pickup';
    final urls = <String>[
      driverProgressOrderEP(type, id),
      '$BASE_URL/driver/orders/$type/$id/$slug',
      '$BASE_URL/order-tracking/$type/$id/progress',
    ];

    Response? last;
    for (final url in urls) {
      last = await _dio.post(
        url,
        data: {'action': action},
        options: _auth,
      );
      final parsed = _trackingFrom(last);
      if (parsed != null) return parsed;

      last = await _dio.get(
        url,
        queryParameters: {'action': action},
        options: _auth,
      );
      final fromGet = _trackingFrom(last);
      if (fromGet != null) return fromGet;
    }

    throw Exception(_msg(last?.data, 'تعذر تحديث حالة الطلب'));
  }

  OrderTrackingData? _trackingFrom(Response res) {
    if (res.statusCode != 200 || res.data is! Map) return null;
    final map = Map<String, dynamic>.from(res.data as Map);
    final data = map['data'];
    if (data is! Map) return null;
    return OrderTrackingData.fromJson(Map<String, dynamic>.from(data));
  }

  String _msg(dynamic data, String fallback) {
    if (data is Map) {
      final m = data['message'];
      if (m is String && m.trim().isNotEmpty) return m;
    }
    return fallback;
  }
}
