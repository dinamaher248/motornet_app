import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:motorent/constants/app_assets.dart';
import 'package:motorent/data/local/auth_prefs.dart';
import 'package:motorent/data/local/cache_helper.dart';
import 'package:motorent/data/remote/url_api.dart';
import 'package:motorent/features/vendor_interface/presentation/pages/vendor_billing_choice_page.dart';
import 'package:motorent/widgets/RootShell.dart';
import 'package:motorent/widgets/auth/auth_theme.dart';
import 'package:motorent/widgets/auth/login_decor.dart';

/// يظهر لصاحب النشاط بعد التسجيل لاختيار نوع العمل: طلبات / حجوزات / خدمات.
class VendorBusinessTypePage extends StatefulWidget {
  const VendorBusinessTypePage({super.key});

  @override
  State<VendorBusinessTypePage> createState() => _VendorBusinessTypePageState();
}

class _VendorBusinessTypePageState extends State<VendorBusinessTypePage> {
  bool _saving = false;

  Future<void> _choose(String hubSection) async {
    if (_saving) return;
    setState(() => _saving = true);

    try {
      await AuthPrefs.saveVendorHubSection(hubSection);

      final listingKind =
          hubSection == 'services' ? 'profession' : 'place';
      final token = CacheHelper.getData(key: 'token')?.toString();
      if (token != null && token.isNotEmpty) {
        try {
          await Dio().post(
            vendorStoreUpdateEP,
            data: FormData.fromMap({
              'listing_kind': listingKind,
              'hub_section': hubSection,
            }),
            options: Options(
              headers: {
                'Authorization': 'Bearer $token',
                'Accept': 'application/json',
              },
              validateStatus: (s) => s != null && s < 600,
            ),
          );
        } catch (_) {
          // يمكن إكمال إعداد المتجر لاحقاً من لوحة صاحب النشاط.
        }
      }

      if (!mounted) return;
      if (hubSection == 'orders') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const VendorBillingChoicePage()),
        );
        return;
      }
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const RootShell()),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AuthTheme.creamBg,
        body: Container(
          decoration: AuthTheme.screenBackground(),
          child: Stack(
            children: [
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 110,
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: LoginCitySkylinePainter(
                      color: AuthTheme.skyline.withValues(alpha: 0.55),
                    ),
                  ),
                ),
              ),
              SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(22),
                          child: Image.asset(
                            AppAssets.appIcon,
                            width: 88,
                            height: 88,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'اختر نوع النشاط',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: AuthTheme.textDark,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'بعد التسجيل اختر النوع المناسب لنشاطك. هذا يحدد شكل متجرك والتصنيفات الظاهرة للعملاء.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 14,
                          color: AuthTheme.textMuted,
                          height: 1.55,
                        ),
                      ),
                      const SizedBox(height: 28),
                      _BusinessTypeCard(
                        title: 'طلبات',
                        description:
                            'لبيع منتجات وتوصيلها للعميل، مثل سوبر ماركت أو مطعم أو صيدلية. العميل يطلب والمنتج يوصل لعنوانه.',
                        icon: Icons.shopping_bag_outlined,
                        accent: AuthTheme.primary,
                        loading: _saving,
                        onTap: () => _choose('orders'),
                      ),
                      const SizedBox(height: 14),
                      _BusinessTypeCard(
                        title: 'حجوزات',
                        description:
                            'لحجز موعد أو مكان مسبقاً، مثل فندق أو عيادة أو قاعة أو صالون. العميل يختار وقتاً ويحجز.',
                        icon: Icons.event_available_outlined,
                        accent: const Color(0xFF2563EB),
                        loading: _saving,
                        onTap: () => _choose('bookings'),
                      ),
                      const SizedBox(height: 14),
                      _BusinessTypeCard(
                        title: 'خدمات الصنايعيه والحرفيين',
                        description:
                            'لتقديم مهنة أو خدمة حسب الطلب، مثل سباك أو كهربائي أو نجار. العميل يتصل بك مباشرة وأنت تنفّذ الخدمة.',
                        icon: Icons.handyman_outlined,
                        accent: const Color(0xFF0C9F6A),
                        loading: _saving,
                        onTap: () => _choose('services'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BusinessTypeCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final Color accent;
  final bool loading;
  final VoidCallback onTap;

  const _BusinessTypeCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.accent,
    required this.loading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: loading ? null : onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AuthTheme.fieldBorder),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: accent, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AuthTheme.textDark,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      description,
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 13,
                        color: AuthTheme.textMuted,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 16,
                color: loading ? AuthTheme.textMuted : accent,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
