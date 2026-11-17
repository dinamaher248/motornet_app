import 'package:geolocator/geolocator.dart';

/// إحداثيات العميل الحالية لإرسالها مع قوائم الطلبات والحجوزات
/// وخدمات الصنايعيه والحرفيين (الأقرب أولاً).
class UserLatLng {
  final double lat;
  final double lng;

  const UserLatLng(this.lat, this.lng);
}

/// يرجع `null` لو الصلاحية مرفوضة أو الـ GPS مقفول — والقوائم تعمل بدون ترتيب مسافة.
Future<UserLatLng?> getUserLatLng() async {
  try {
    if (!await Geolocator.isLocationServiceEnabled()) {
      final last = await Geolocator.getLastKnownPosition();
      return last == null ? null : UserLatLng(last.latitude, last.longitude);
    }

    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm != LocationPermission.whileInUse &&
        perm != LocationPermission.always) {
      return null;
    }

    try {
      // geolocator 11.x: المهلة وبدقة الموقع عبر المعاملات المباشرة.
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 8),
      );
      return UserLatLng(pos.latitude, pos.longitude);
    } catch (_) {
      // انتهت المهلة: نستخدم آخر موقع معروف بدل ما تفضل القائمة معلّقة.
      final last = await Geolocator.getLastKnownPosition();
      return last == null ? null : UserLatLng(last.latitude, last.longitude);
    }
  } catch (_) {
    return null;
  }
}
