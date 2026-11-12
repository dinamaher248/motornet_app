import 'package:dio/dio.dart';
import 'package:motorent/data/local/cache_helper.dart';
import 'package:motorent/data/remote/url_api.dart';
import 'package:motorent/features/notifications/core/error/exceptions.dart';
import 'package:motorent/features/notifications/data/models/notification_model.dart';
import 'package:motorent/features/notifications/domain/entities/app_notification.dart';

abstract class NotificationRemoteDataSource {
  Future<NotificationsPageResult> getNotifications();

  Future<void> markAsRead(int id);

  Future<void> markAllAsRead();
}

class NotificationRemoteDataSourceImpl implements NotificationRemoteDataSource {
  final Dio dio;

  NotificationRemoteDataSourceImpl({Dio? dio}) : dio = dio ?? Dio();

  Options get _authOptions => Options(
        headers: {
          'Authorization': 'Bearer ${CacheHelper.getData(key: 'token')}',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        sendTimeout: const Duration(seconds: 20),
        receiveTimeout: const Duration(seconds: 20),
        validateStatus: (status) => status != null && status < 600,
      );

  @override
  Future<NotificationsPageResult> getNotifications() async {
    try {
      final response = await dio.get(notificationsEP, options: _authOptions);

      if (response.statusCode != 200 || response.data is! Map) {
        throw ServerException(
          _messageFrom(response.data, fallback: 'تعذر تحميل الإشعارات'),
          statusCode: response.statusCode,
        );
      }

      final map = Map<String, dynamic>.from(response.data as Map);
      final listRaw = map['data'] ?? map['notifications'];
      final list = listRaw is List ? listRaw : const [];

      final notifications = list
          .whereType<Map>()
          .map((e) => NotificationModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();

      final unreadFromApi = map['unread_count'] ?? map['unreadCount'];
      final unreadCount = unreadFromApi != null
          ? _asInt(unreadFromApi)
          : notifications.where((n) => !n.isRead).length;

      return NotificationsPageResult(
        notifications: notifications,
        unreadCount: unreadCount,
      );
    } on DioException catch (e) {
      throw _mapDio(e, 'تعذر تحميل الإشعارات');
    }
  }

  @override
  Future<void> markAsRead(int id) async {
    try {
      final response = await dio.post(
        notificationMarkReadEP(id),
        options: _authOptions,
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw ServerException(
          _messageFrom(response.data, fallback: 'تعذر تحديث الإشعار'),
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      throw _mapDio(e, 'تعذر تحديث الإشعار');
    }
  }

  @override
  Future<void> markAllAsRead() async {
    try {
      final response = await dio.post(
        notificationsMarkAllReadEP,
        options: _authOptions,
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw ServerException(
          _messageFrom(response.data, fallback: 'تعذر تحديث الإشعارات'),
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      throw _mapDio(e, 'تعذر تحديث الإشعارات');
    }
  }

  int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  String _messageFrom(dynamic data, {required String fallback}) {
    if (data is Map) {
      final message = data['message']?.toString();
      if (message != null && message.trim().isNotEmpty) return message;
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
