import 'package:dio/dio.dart';
import 'package:motorent/data/local/cache_helper.dart';
import 'package:motorent/data/remote/url_api.dart';
import 'package:url_launcher/url_launcher.dart';

class PlaceBookingService {
  PlaceBookingService._();

  static const _countKey = 'my_bookings_count';
  static final Dio _dio = Dio();

  static Options get _auth => Options(
        headers: {
          'Authorization': 'Bearer ${CacheHelper.getData(key: 'token')}',
          'Accept': 'application/json',
        },
        validateStatus: (s) => s != null && s < 600,
      );

  static int localCount() {
    final raw = CacheHelper.getData(key: _countKey);
    if (raw is int) return raw;
    return int.tryParse(raw?.toString() ?? '') ?? 0;
  }

  static Future<int> fetchCount() async {
    try {
      final res = await _dio.get(servicesBookingsCountEP, options: _auth);
      if (res.statusCode == 200 && res.data is Map) {
        final map = Map<String, dynamic>.from(res.data as Map);
        final nested = map['data'] is Map
            ? Map<String, dynamic>.from(map['data'] as Map)
            : map;
        final count = int.tryParse(
              '${nested['bookings_count'] ?? map['bookings_count'] ?? ''}',
            ) ??
            0;
        await CacheHelper.saveData(key: _countKey, value: count);
        return count;
      }
    } catch (_) {}
    return localCount();
  }

  static Future<int> recordBooking({
    required int storeId,
    String kind = 'place',
  }) async {
    var count = localCount() + 1;
    await CacheHelper.saveData(key: _countKey, value: count);
    try {
      final res = await _dio.post(
        servicesBookingsEP,
        data: {'store_id': storeId, 'kind': kind},
        options: _auth,
      );
      if ((res.statusCode == 200 || res.statusCode == 201) &&
          res.data is Map) {
        final map = Map<String, dynamic>.from(res.data as Map);
        final nested = map['data'] is Map
            ? Map<String, dynamic>.from(map['data'] as Map)
            : map;
        final server = int.tryParse(
          '${nested['bookings_count'] ?? map['bookings_count'] ?? ''}',
        );
        if (server != null) {
          count = server;
          await CacheHelper.saveData(key: _countKey, value: count);
        }
      }
    } catch (_) {}
    return count;
  }

  static String? normalizePhone(String? raw) {
    if (raw == null) return null;
    final cleaned = raw.replaceAll(RegExp(r'[^\d+]'), '');
    if (cleaned.length < 8) return null;
    return cleaned;
  }

  static Future<bool> callAndBook({
    required String? phone,
    required int storeId,
    String kind = 'place',
  }) async {
    final cleaned = normalizePhone(phone);
    if (cleaned == null) return false;
    final uri = Uri(scheme: 'tel', path: cleaned);
    final launched = await launchUrl(uri);
    if (launched) {
      await recordBooking(storeId: storeId, kind: kind);
    }
    return launched;
  }
}
