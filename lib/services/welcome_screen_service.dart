import 'package:dio/dio.dart';
import 'package:motorent/data/remote/url_api.dart';
import 'package:motorent/models/welcome_screen_config.dart';

class WelcomeScreenService {
  static Future<WelcomeScreenConfig> fetch() async {
    try {
      final response = await Dio().get(
        welcomeScreenEP,
        options: Options(
          headers: {'Accept': 'application/json'},
          sendTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
          validateStatus: (status) => status != null && status < 600,
        ),
      );

      if (response.statusCode == 200 && response.data is Map) {
        return WelcomeScreenConfig.fromJson(
          Map<String, dynamic>.from(response.data as Map),
        );
      }
    } catch (e) {
      print('welcome screen fetch error: $e');
    }

    return WelcomeScreenConfig.defaults();
  }
}
