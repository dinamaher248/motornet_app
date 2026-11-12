import 'package:flutter/material.dart';
import 'package:motorent/data/local/cache_helper.dart';
import 'package:motorent/pages/LoginPage.dart';
import 'package:motorent/pages/PlansPage.dart';
import 'package:motorent/pages/splash_page.dart';
import 'package:motorent/widgets/auth/auth_theme.dart';

/// شاشة انتظار موافقة الإدارة على الاشتراك.
class SubscriptionPendingPage extends StatelessWidget {
  final String? message;

  const SubscriptionPendingPage({super.key, this.message});

  Future<void> _logout(BuildContext context) async {
    await CacheHelper.removeData(key: 'token');
    await CacheHelper.removeData(key: 'status');
    if (!context.mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => LoginPage()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'بانتظار الموافقة',
            style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700),
          ),
          actions: [
            IconButton(
              onPressed: () => _logout(context),
              icon: const Icon(Icons.logout, color: Color(0xffd34949)),
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.hourglass_top, size: 64, color: AuthTheme.primary),
              const SizedBox(height: 16),
              Text(
                message ??
                    'تم استلام طلب الاشتراك وهو قيد المراجعة من الإدارة.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'بعد القبول سجّل الدخول مرة أخرى للمتابعة.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Cairo',
                  color: AuthTheme.textMuted,
                ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const SplashPage()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AuthTheme.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text(
                    'تحديث الحالة',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => PlansPage()),
                  );
                },
                child: const Text(
                  'تعديل طلب الاشتراك / باقة أخرى',
                  style: TextStyle(fontFamily: 'Cairo'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
