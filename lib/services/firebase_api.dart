import 'dart:async';

import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import '../data/local/cache_helper.dart';
import '../data/remote/url_api.dart';

class FirebaseApi {
  final _firebaseMessaging = FirebaseMessaging.instance;

  Future<void> initNotification() async {
    await _firebaseMessaging
        .requestPermission()
        .timeout(const Duration(seconds: 10));

    try {
      await _firebaseMessaging
          .subscribeToTopic('motorent')
          .timeout(const Duration(seconds: 5));
    } catch (e) {
      print('Topic subscription failed: $e');
    }

    await _syncFcmToken();

    _firebaseMessaging.onTokenRefresh.listen((_) => _syncFcmToken());
  }

  Future<void> _syncFcmToken() async {
    final userId = CacheHelper.getData(key: 'id');
    if (userId == null) {
      return;
    }

    final fcmToken = await _firebaseMessaging
        .getToken()
        .timeout(const Duration(seconds: 10));
    if (fcmToken == null) {
      return;
    }

    try {
      final response = await Dio().post(
        setFcmToken,
        data: {
          'id': userId,
          'token': fcmToken,
        },
        options: Options(
          sendTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
          headers: {
            if (CacheHelper.getData(key: 'token') != null)
              'Authorization':
                  'Bearer ${CacheHelper.getData(key: 'token')}',
          },
        ),
      );

      print('FCM token synced: ${response.data}');
    } catch (e) {
      print('FCM token sync failed: $e');
    }
  }
}
