import 'package:dio/dio.dart';
import 'package:motorent/data/local/cache_helper.dart';
import 'package:motorent/data/remote/url_api.dart';

class ProfileService {
  final Dio _dio = Dio();

  Options get _authOptions => Options(
        headers: {
          'Authorization': 'Bearer ${CacheHelper.getData(key: 'token')}',
          'Accept': 'application/json',
        },
        sendTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        validateStatus: (status) => status != null && status < 600,
      );

  Future<Map<String, dynamic>> updateProfile({
    String? name,
    String? username,
    String? phone,
    String? email,
    String? governorate,
    String? area,
    String? imagePath,
  }) async {
    final map = <String, dynamic>{};

    if (name != null) map['name'] = name.trim();
    if (username != null) map['username'] = username.trim();
    if (phone != null) map['phone'] = phone.trim();
    if (email != null) map['email'] = email.trim();
    if (governorate != null) map['governorate'] = governorate.trim();
    if (area != null) map['area'] = area.trim();

    if (imagePath != null && imagePath.isNotEmpty) {
      final extension = imagePath.split('.').last.toLowerCase();
      final safeExtension =
          ['jpg', 'jpeg', 'png', 'webp'].contains(extension) ? extension : 'jpg';
      map['image'] = await MultipartFile.fromFile(
        imagePath,
        filename: 'profile_${DateTime.now().millisecondsSinceEpoch}.$safeExtension',
      );
    }

    final response = await _dio.put(
      updateProfileEP,
      data: FormData.fromMap(map),
      options: _authOptions.copyWith(
        contentType: 'multipart/form-data',
      ),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(_messageFromResponse(response));
    }

    final data = response.data;
    Map<String, dynamic>? user;
    if (data is Map) {
      final message = data['message'];
      if (message is Map) {
        user = Map<String, dynamic>.from(message);
      }
    }

    if (user != null) {
      await _cacheUserFields(user);
    }

    return user ?? {};
  }

  Future<void> _cacheUserFields(Map<String, dynamic> user) async {
    if (user['name'] != null) {
      await CacheHelper.saveData(key: 'name', value: user['name'].toString());
    }
    if (user['username'] != null) {
      await CacheHelper.saveData(
        key: 'username',
        value: user['username'].toString(),
      );
    }
    if (user['email'] != null) {
      await CacheHelper.saveData(key: 'email', value: user['email'].toString());
    }
    if (user['phone'] != null) {
      await CacheHelper.saveData(key: 'phone', value: user['phone'].toString());
    }
  }

  String _messageFromResponse(Response response) {
    final data = response.data;
    if (data is Map) {
      if (data['message'] is String) return data['message'] as String;
      if (data['errors'] is Map) {
        final errors = data['errors'] as Map;
        for (final value in errors.values) {
          if (value is List && value.isNotEmpty) {
            return value.first.toString();
          }
        }
      }
    }
    return 'تعذر تحديث البيانات';
  }
}
