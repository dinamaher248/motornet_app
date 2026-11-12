import 'dart:io';

import 'package:dio/dio.dart';
import 'package:motorent/constants/app_support.dart';
import 'package:motorent/data/local/cache_helper.dart';
import 'package:motorent/data/remote/url_api.dart';
import 'package:motorent/features/my_account/core/error/exceptions.dart';
import 'package:motorent/features/my_account/data/models/profile_model.dart';
import 'package:motorent/features/my_account/domain/entities/profile_data.dart';

abstract class ProfileRemoteDataSource {
  Future<ProfileData> getProfile();

  Future<ProfileUser> updateProfile({
    String? name,
    String? phone,
    String? email,
    String? vehicleType,
    String? password,
    String? passwordConfirmation,
    String? governorate,
    String? area,
    File? imageFile,
    File? nidImageFile,
  });
}

class ProfileRemoteDataSourceImpl implements ProfileRemoteDataSource {
  final Dio dio;

  ProfileRemoteDataSourceImpl({Dio? dio}) : dio = dio ?? Dio();

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
  Future<ProfileData> getProfile() async {
    try {
      final response = await dio.get(profileGetEP, options: _authOptions);

      if (response.statusCode == 200 && response.data is Map) {
        final profile = ProfileModel.fromJson(
          Map<String, dynamic>.from(response.data as Map),
        );
        await _cacheUser(profile.user);
        return profile;
      }

      // Fallback: /me endpoint used by older backends
      final meResponse = await dio.get(getDriver, options: _authOptions);
      if (meResponse.statusCode == 200 && meResponse.data is Map) {
        final map = Map<String, dynamic>.from(meResponse.data as Map);
        final userRaw = map['user'] is Map
            ? Map<String, dynamic>.from(map['user'] as Map)
            : map['message'] is Map
                ? Map<String, dynamic>.from(map['message'] as Map)
                : map;
        return ProfileData(
          user: ProfileUserModel.fromJson(userRaw),
          settings: const ProfileSettingsModel(
            supportPhone: AppSupport.phone,
            privacyPolicyUrl: '',
          ),
        );
      }

      throw ServerException(
        _messageFrom(response.data, fallback: 'تعذر تحميل الملف الشخصي'),
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      throw _mapDio(e, 'تعذر تحميل الملف الشخصي');
    }
  }

  @override
  Future<ProfileUser> updateProfile({
    String? name,
    String? phone,
    String? email,
    String? vehicleType,
    String? password,
    String? passwordConfirmation,
    String? governorate,
    String? area,
    File? imageFile,
    File? nidImageFile,
  }) async {
    try {
      final map = <String, dynamic>{};
      if (name != null) map['name'] = name.trim();
      if (phone != null) map['phone'] = phone.trim();
      if (email != null) map['email'] = email.trim();
      if (vehicleType != null && vehicleType.trim().isNotEmpty) {
        map['vehicle_type'] = vehicleType.trim();
      }
      if (governorate != null) map['governorate'] = governorate.trim();
      if (area != null) map['area'] = area.trim();
      if (password != null && password.trim().isNotEmpty) {
        map['password'] = password.trim();
        map['password_confirmation'] =
            (passwordConfirmation ?? password).trim();
      }

      if (imageFile != null) {
        map['image'] = await _filePart(imageFile, 'profile');
      }
      if (nidImageFile != null) {
        map['nid_image'] = await _filePart(nidImageFile, 'nid');
      }

      // Prefer POST /profile/update, fall back to PUT /profile
      Response response = await dio.post(
        profileUpdateEP,
        data: FormData.fromMap(map),
        options: _authOptions.copyWith(contentType: 'multipart/form-data'),
      );

      if (response.statusCode == 404 || response.statusCode == 405) {
        response = await dio.put(
          updateProfileEP,
          data: FormData.fromMap(map),
          options: _authOptions.copyWith(contentType: 'multipart/form-data'),
        );
      }

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw ServerException(
          _messageFrom(response.data, fallback: 'تعذر تحديث البيانات'),
          statusCode: response.statusCode,
        );
      }

      final user = _extractUser(response.data);
      await _cacheUser(user);
      return user;
    } on DioException catch (e) {
      throw _mapDio(e, 'تعذر تحديث البيانات');
    }
  }

  Future<MultipartFile> _filePart(File file, String prefix) async {
    final path = file.path;
    final extension = path.split('.').last.toLowerCase();
    final safeExtension =
        ['jpg', 'jpeg', 'png', 'webp'].contains(extension) ? extension : 'jpg';
    return MultipartFile.fromFile(
      path,
      filename:
          '${prefix}_${DateTime.now().millisecondsSinceEpoch}.$safeExtension',
    );
  }

  ProfileUser _extractUser(dynamic data) {
    if (data is Map) {
      final map = Map<String, dynamic>.from(data);
      final nested = map['data'] is Map
          ? Map<String, dynamic>.from(map['data'] as Map)['user']
          : null;
      if (nested is Map) {
        return ProfileUserModel.fromJson(Map<String, dynamic>.from(nested));
      }
      final message = map['message'];
      if (message is Map) {
        return ProfileUserModel.fromJson(Map<String, dynamic>.from(message));
      }
      final user = map['user'];
      if (user is Map) {
        return ProfileUserModel.fromJson(Map<String, dynamic>.from(user));
      }
      if (map.containsKey('id') || map.containsKey('name')) {
        return ProfileUserModel.fromJson(map);
      }
    }
    throw const ServerException('استجابة غير متوقعة من السيرفر');
  }

  Future<void> _cacheUser(ProfileUser user) async {
    await CacheHelper.saveData(key: 'name', value: user.name);
    await CacheHelper.saveData(key: 'phone', value: user.phone);
    if (user.email != null) {
      await CacheHelper.saveData(key: 'email', value: user.email);
    }
    if (user.image != null) {
      await CacheHelper.saveData(key: 'image', value: user.image);
    }
    if (user.title != null) {
      await CacheHelper.saveData(key: 'title', value: user.title);
    }
    if (user.vehicleType != null) {
      await CacheHelper.saveData(key: 'vehicle_type', value: user.vehicleType);
    }
  }

  String _messageFrom(dynamic data, {required String fallback}) {
    if (data is Map) {
      final message = data['message'];
      if (message is String && message.trim().isNotEmpty) return message;
      final errors = data['errors'];
      if (errors is Map && errors.isNotEmpty) {
        final first = errors.values.first;
        if (first is List && first.isNotEmpty) return first.first.toString();
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
