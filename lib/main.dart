import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:motorent/firebase_options.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_paymob/flutter_paymob.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:motorent/data/themes_data.dart';
import 'package:motorent/pages/splash_page.dart';
import 'package:motorent/providers/home_provider.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

import 'data/local/AppDatabaseHelper.dart';
import 'data/local/cache_helper.dart';
import 'services/firebase_api.dart';
import 'services/notification_navigator.dart';
import 'services/notification_store.dart';
import 'utils/notification_kind.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;
  await CacheHelper.init();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    await _setupFirebaseServices();

    final messaging = FirebaseMessaging.instance;
    await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    await messaging.subscribeToTopic('motorent');
    print('Subscribed to topic: motorent');
  } catch (e) {
    print('Firebase init failed: $e');
  }

  final dbHelper = AppDatabaseHelper();
  unawaited(dbHelper.database);

  runApp(const App());

  if (CacheHelper.getData(key: 'id') != null) {
    unawaited(
      FirebaseApi()
          .initNotification()
          .timeout(const Duration(seconds: 10))
          .catchError((e) => print('FCM token sync skipped: $e')),
    );
  }
}

Future<void> _setupFirebaseServices() async {
  try {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@drawable/app_notification_icon');
    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
    );
    await flutterLocalNotificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (response) {
        final ctx = Get.key.currentContext;
        if (ctx == null) return;
        unawaited(NotificationNavigator.openFromPayload(ctx, response.payload));
      },
    );

    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'fcm_sound_channel_v2',
      'إشعارات التطبيق',
      description: 'قناة إشعارات توصيلة برو',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    );

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);
  } catch (e) {
    print('Local notifications setup failed: $e');
  }
}

class App extends StatefulWidget {
  const App({Key? key}) : super(key: key);
  @override
  _AppState createState() => _AppState();
}

class _AppState extends State<App> {
  @override
  void initState() {
    super.initState();
    requestNotificationPermission();

    FirebaseMessaging.onMessage.listen(_showNotification);

    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      unawaited(_handleNotificationOpen(message));
    });

    FirebaseMessaging.instance.getInitialMessage().then((message) {
      if (message != null) {
        unawaited(_handleNotificationOpen(message));
      }
    });
  }

  Future<void> requestNotificationPermission() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    if (Platform.isAndroid) {
      // لأندرويد 13+ هيطلب الإذن Runtime
      NotificationSettings settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        print('User granted notification permission');
      } else if (settings.authorizationStatus == AuthorizationStatus.denied) {
        print('User denied notification permission');
      } else {
        print('Notification permission not determined or restricted');
      }
    } else {
      // iOS مثلاً
      NotificationSettings settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      print('iOS notification status: ${settings.authorizationStatus}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData baseTheme = lightModeTheme;

    return MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => HomeProvider())],
      child: GetMaterialApp(
        defaultTransition: Transition.rightToLeft,
        transitionDuration: const Duration(milliseconds: 500),
        debugShowCheckedModeBanner: false,
        title: 'توصيلة برو',
        theme: baseTheme,
        home: const SplashPage(),
        builder: (context, child) {
          return Directionality(
            textDirection:
                TextDirection.rtl, // يخلي كل التطبيق من اليسار لليمين
            child: child!,
          );
        },
      ),
    );
  }
}

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  const AndroidInitializationSettings androidSettings =
      AndroidInitializationSettings('@drawable/app_notification_icon');
  await flutterLocalNotificationsPlugin.initialize(
    const InitializationSettings(android: androidSettings),
  );

  await _showNotification(message);
}

Future<void> requestNotificationPermission() async {
  FirebaseMessaging messaging = FirebaseMessaging.instance;

  if (Platform.isAndroid) {
    // Only needed on Android 13+
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('User granted notification permission');
    } else if (settings.authorizationStatus == AuthorizationStatus.denied) {
      print('User denied notification permission');
    } else {
      print('Notification permission not determined or restricted');
    }
  }
}

Future<void> _handleNotificationOpen(RemoteMessage message) async {
  await _persistNotification(message);

  final ctx = Get.key.currentContext;
  if (ctx == null) return;

  final data = message.data;
  await NotificationNavigator.openFromPayload(
    ctx,
    jsonEncode({
      'title': data['head'] ?? data['title'] ?? message.notification?.title,
      'body': data['desc'] ?? data['body'] ?? message.notification?.body,
      'action': NotificationKind.normalize(data['action']?.toString()),
      'ref_id': data['ref_id']?.toString() ??
          data['order_id']?.toString() ??
          data['related_id']?.toString() ??
          data['url']?.toString(),
      'topic': data['mtopic']?.toString() ?? 'motorent',
    }),
  );
}

Future<void> _persistNotification(RemoteMessage message) async {
  final data = message.data;
  final title = (data['head'] ??
          data['title'] ??
          message.notification?.title ??
          '')
      .trim();
  final body = (data['desc'] ??
          data['body'] ??
          message.notification?.body ??
          '')
      .trim();

  if (title.isEmpty && body.isEmpty) {
    return;
  }

  await NotificationStore.instance.saveFromPush(
    title: title.isNotEmpty ? title : 'إشعار',
    body: body,
    action: data['action']?.toString() ?? '',
    topic: data['mtopic']?.toString() ?? 'motorent',
    refId: data['ref_id']?.toString() ??
        data['order_id']?.toString() ??
        data['related_id']?.toString(),
    url: data['url']?.toString(),
  );
}

Future<void> _showNotification(RemoteMessage message) async {
  final data = message.data;
  final title = (data['head'] ??
          data['title'] ??
          message.notification?.title ??
          '')
      .trim();
  final body = (data['desc'] ??
          data['body'] ??
          message.notification?.body ??
          '')
      .trim();

  if (title.isEmpty && body.isEmpty) {
    return;
  }

  final action = NotificationKind.normalize(data['action']?.toString());

  await NotificationStore.instance.saveFromPush(
    title: title.isNotEmpty ? title : 'إشعار',
    body: body,
    action: action,
    topic: data['mtopic']?.toString() ?? 'motorent',
    refId: data['ref_id']?.toString() ??
        data['order_id']?.toString() ??
        data['related_id']?.toString(),
    url: data['url']?.toString(),
  );

  const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
    'fcm_sound_channel_v2',
    'إشعارات التطبيق',
    channelDescription: 'قناة إشعارات توصيلة برو',
    importance: Importance.max,
    priority: Priority.high,
    playSound: true,
    enableVibration: true,
    icon: '@drawable/app_notification_icon',
  );

  const NotificationDetails notificationDetails = NotificationDetails(
    android: androidDetails,
  );

  await flutterLocalNotificationsPlugin.show(
    message.hashCode,
    title.isNotEmpty ? title : 'إشعار',
    body,
    notificationDetails,
    payload: jsonEncode({
      'title': title.isNotEmpty ? title : 'إشعار',
      'body': body,
      'action': action,
      'ref_id': data['ref_id']?.toString() ??
          data['order_id']?.toString() ??
          data['related_id']?.toString() ??
          data['url']?.toString(),
      'topic': data['mtopic']?.toString() ?? 'motorent',
    }),
  );
}
