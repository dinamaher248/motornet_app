import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:motorent/constants/app_assets.dart';
import 'package:motorent/data/local/cache_helper.dart';
import 'package:motorent/data/remote/url_api.dart';
import 'package:motorent/features/vendor_interface/data/models/vendor_models.dart';
import 'package:motorent/widgets/RootShell.dart';
import 'package:motorent/widgets/auth/auth_theme.dart';
import 'package:motorent/widgets/auth/login_decor.dart';

/// يظهر بعد اختيار «طلبات» ليختار صاحب النشاط: عمولة أو سعر ثابت لكل أوردر.
class VendorBillingChoicePage extends StatefulWidget {
  const VendorBillingChoicePage({super.key});

  @override
  State<VendorBillingChoicePage> createState() => _VendorBillingChoicePageState();
}

class _VendorBillingChoicePageState extends State<VendorBillingChoicePage> {
  bool _loading = true;
  bool _saving = false;
  String? _error;
  VendorWalletModel? _wallet;

  Options get _auth {
    final token = CacheHelper.getData(key: 'token')?.toString() ?? '';
    return Options(
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
      validateStatus: (s) => s != null && s < 600,
    );
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await Dio().get(vendorWalletEP, options: _auth);
      if (!mounted) return;
      final data = res.data is Map ? Map<String, dynamic>.from(res.data as Map) : <String, dynamic>{};
      final payload = data['data'] is Map
          ? Map<String, dynamic>.from(data['data'] as Map)
          : data;
      final wallet = VendorWalletModel.fromJson(payload);
      final showCommission = wallet.commissionOptionEnabled;
      final showFixed = wallet.fixedFeeOptionEnabled;

      if (!showCommission && !showFixed) {
        _goHome();
        return;
      }
      if (showCommission != showFixed) {
        final mode = showFixed ? 'fixed_fee' : 'commission';
        await _save(mode, skipHomeIfFail: false);
        return;
      }

      setState(() {
        _wallet = wallet;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'تعذر تحميل خيارات الفوترة';
      });
    }
  }

  Future<void> _save(String mode, {bool skipHomeIfFail = true}) async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      final res = await Dio().post(
        vendorWalletBillingModeEP,
        data: {'billing_mode': mode},
        options: _auth,
      );
      if (!mounted) return;
      final ok = (res.statusCode ?? 0) >= 200 && (res.statusCode ?? 0) < 300;
      if (!ok && skipHomeIfFail) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذر حفظ الاختيار، حاول مرة أخرى')),
        );
        return;
      }
      _goHome();
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      if (skipHomeIfFail) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذر حفظ الاختيار، حاول مرة أخرى')),
        );
      } else {
        _goHome();
      }
    }
  }

  void _goHome() {
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const RootShell()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final wallet = _wallet;
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
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : SingleChildScrollView(
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
                              'اختر طريقة الفوترة',
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
                              'القيم يحددها التطبيق من لوحة الإدارة، وتتحدث فور تغييرها.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 14,
                                color: AuthTheme.textMuted,
                                height: 1.55,
                              ),
                            ),
                            const SizedBox(height: 28),
                            if (_error != null)
                              Text(
                                _error!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontFamily: 'Cairo',
                                  color: Colors.red,
                                ),
                              )
                            else if (wallet != null) ...[
                              if (wallet.commissionOptionEnabled)
                                _ChoiceCard(
                                  title:
                                      'عمولة ${wallet.orderCommissionPercent.toStringAsFixed(0)}%',
                                  subtitle: 'نسبة من قيمة كل طلب',
                                  icon: Icons.percent,
                                  loading: _saving,
                                  onTap: () => _save('commission'),
                                ),
                              if (wallet.commissionOptionEnabled &&
                                  wallet.fixedFeeOptionEnabled)
                                const SizedBox(height: 14),
                              if (wallet.fixedFeeOptionEnabled)
                                _ChoiceCard(
                                  title:
                                      '${wallet.orderFixedFee.toStringAsFixed(0)} ج.م لكل أوردر',
                                  subtitle: 'سعر ثابت لكل طلب',
                                  icon: Icons.payments_outlined,
                                  loading: _saving,
                                  onTap: () => _save('fixed_fee'),
                                ),
                            ],
                            TextButton(
                              onPressed: _saving ? null : _goHome,
                              child: const Text(
                                'تخطي الآن',
                                style: TextStyle(fontFamily: 'Cairo'),
                              ),
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

class _ChoiceCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool loading;
  final VoidCallback onTap;

  const _ChoiceCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.loading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: loading ? null : onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AuthTheme.fieldBorder),
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: AuthTheme.primary.withValues(alpha: 0.12),
                child: Icon(icon, color: AuthTheme.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 13,
                        color: AuthTheme.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              if (loading)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                const Icon(Icons.chevron_left),
            ],
          ),
        ),
      ),
    );
  }
}
