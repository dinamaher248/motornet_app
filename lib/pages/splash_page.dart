import 'dart:async';



import 'package:dio/dio.dart';

import 'package:motorent/data/local/auth_prefs.dart';

import 'package:motorent/constants/app_assets.dart';
import 'package:motorent/pages/LoginPage.dart';

import 'package:motorent/pages/RegisterPage.dart';

import 'package:motorent/pages/welcome_page.dart';

import 'package:flutter/material.dart';

import 'package:motorent/services/welcome_screen_service.dart';

import 'package:motorent/widgets/RootShell.dart';

import '../data/local/cache_helper.dart';

import '../data/remote/url_api.dart';

import '../services/firebase_api.dart';



class SplashPage extends StatefulWidget {

  const SplashPage({Key? key}) : super(key: key);



  @override

  _SplashPageState createState() => _SplashPageState();

}



class _SplashPageState extends State<SplashPage> {

  @override

  void initState() {

    super.initState();

    checkUserStatus();

  }



  Future<void> checkUserStatus() async {

    final token = CacheHelper.getData(key: 'token');



    if (token == null) {

      if (AuthPrefs.hasCompletedRegistration) {

        navigateTo(LoginPage());

        return;

      }



      final welcomeConfig = await WelcomeScreenService.fetch();

      if (welcomeConfig.enabled) {

        navigateTo(WelcomePage(config: welcomeConfig));

        return;

      }



      navigateTo(const RegisterPage());

      return;

    }



    try {

      final response = await Dio().get(

        checkStatusEP,

        options: Options(

          headers: {'Authorization': 'Bearer $token'},

          sendTimeout: const Duration(seconds: 10),

          receiveTimeout: const Duration(seconds: 10),

        ),

      );



      if (response.statusCode == 200) {

        String status = response.data['status'];



        if (status == 'success') {

          await AuthPrefs.markRegistrationCompleted();

          final user = response.data['user'];
          if (user is Map) {
            final isAdmin = user['is_admin'] == true ||
                user['is_admin'] == 1 ||
                user['is_admin'] == '1' ||
                user['title']?.toString() == 'admin';
            if (isAdmin) {
              await CacheHelper.saveData(key: 'is_admin', value: true);
              await CacheHelper.saveData(key: 'title', value: 'admin');
              final keys = user['permission_keys'] ?? user['permissions'];
              String stored = '*';
              if (keys is List) {
                stored = keys.map((e) => e.toString()).join(',');
              } else if (keys != null) {
                stored = keys.toString();
              }
              await CacheHelper.saveData(key: 'admin_permissions', value: stored);
              await CacheHelper.saveData(
                key: 'is_super_admin',
                value: user['is_super_admin'] == true ||
                    user['is_super_admin'] == 1 ||
                    user['is_super_admin'] == '1',
              );
            } else {
              await CacheHelper.saveData(key: 'is_admin', value: false);
              final t = user['title']?.toString() ?? '';
              // Normalize vendor→merchant for RootShell
              final title = (t == 'vendor') ? 'merchant' : (t.isEmpty ? 'user' : t);
              await CacheHelper.saveData(key: 'title', value: title);
            }
          }

          unawaited(

            FirebaseApi()

                .initNotification()

                .timeout(const Duration(seconds: 15))

                .catchError((e) => print('FCM init failed: $e')),

          );

          navigateTo(const RootShell());

        } else if (status == 'not_approved' ||
            status == 'expired' ||
            status == 'nosub' ||
            status == 'plans_disabled') {

          await AuthPrefs.markRegistrationCompleted();

          navigateTo(const RootShell());

        } else {

          navigateTo(const RegisterPage());

        }

      } else {

        navigateTo(const RegisterPage());

      }

    } catch (e) {

      print('Error checking status: $e');

      navigateTo(const RegisterPage());

    }

  }



  void navigateTo(Widget page) {

    Timer(const Duration(milliseconds: 500), () {

      if (!mounted) return;

      Navigator.pushReplacement(

        context,

        MaterialPageRoute(builder: (_) => page),

      );

    });

  }



  @override

  Widget build(BuildContext context) {

    return Scaffold(

      backgroundColor: Colors.white,

      body: Center(

        child: Column(

          mainAxisAlignment: MainAxisAlignment.center,

          children: [

            Image.asset(
              AppAssets.appIcon,
              width: 180,
              height: 180,
              fit: BoxFit.cover,
            ),

            const SizedBox(height: 24),

            const CircularProgressIndicator(color: Color(0xffe6910a)),

          ],

        ),

      ),

    );

  }

}


