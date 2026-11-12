import 'package:dio/dio.dart';
import 'package:geolocator/geolocator.dart';
import 'package:motorent/data/local/cache_helper.dart';
import 'package:motorent/data/remote/url_api.dart';

/// Pushes the driver's GPS so the backend can match nearby requests by radius.
class DriverLocationSync {
  DriverLocationSync._();

  static Future<bool> syncNow({bool force = false}) async {
    try {
      final title = CacheHelper.getData(key: 'title')?.toString();
      if (title != 'driver') return false;

      final online = CacheHelper.getData(key: 'is_online');
      final isOnline = online == 1 || online == '1' || online == true;
      if (!isOnline && !force) return false;

      final permission = await Geolocator.checkPermission();
      LocationPermission granted = permission;
      if (permission == LocationPermission.denied) {
        granted = await Geolocator.requestPermission();
      }
      if (granted == LocationPermission.denied ||
          granted == LocationPermission.deniedForever) {
        return false;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 12),
      );

      final token = CacheHelper.getData(key: 'token');
      if (token == null) return false;

      final response = await Dio().post(
        updateDriverLocationEP,
        data: {
          'lat': position.latitude,
          'lng': position.longitude,
          'current_lat': position.latitude,
          'current_lng': position.longitude,
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
          validateStatus: (s) => s != null && s < 600,
          sendTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 15),
        ),
      );

      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  static Future<Map<String, double>?> currentCoords() async {
    try {
      final permission = await Geolocator.checkPermission();
      LocationPermission granted = permission;
      if (permission == LocationPermission.denied) {
        granted = await Geolocator.requestPermission();
      }
      if (granted == LocationPermission.denied ||
          granted == LocationPermission.deniedForever) {
        return null;
      }
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 10),
      );
      return {'lat': position.latitude, 'lng': position.longitude};
    } catch (_) {
      return null;
    }
  }
}
