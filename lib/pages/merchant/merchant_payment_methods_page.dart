import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:motorent/models/merchant_owner_models.dart';
import 'package:motorent/services/merchant_owner_api.dart';
import 'package:motorent/widgets/auth/auth_theme.dart';

class MerchantPaymentMethodsPage extends StatefulWidget {
  const MerchantPaymentMethodsPage({super.key});

  @override
  State<MerchantPaymentMethodsPage> createState() =>
      _MerchantPaymentMethodsPageState();
}

class _MerchantPaymentMethodsPageState extends State<MerchantPaymentMethodsPage> {
  final _api = MerchantOwnerApi();
  final _walletNumberController = TextEditingController();
  final _walletOwnerController = TextEditingController();
  final _walletTypeController = TextEditingController();

  bool _loading = true;
  bool _saving = false;
  bool _payOnDelivery = true;
  bool _payWallet = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _walletNumberController.dispose();
    _walletOwnerController.dispose();
    _walletTypeController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final settings = await _api.fetchPaymentMethods();
      if (!mounted) return;
      setState(() {
        _payOnDelivery = settings.payOnDelivery;
        _payWallet = settings.payWallet;
        _walletNumberController.text = settings.walletNumber ?? '';
        _walletOwnerController.text = settings.walletOwnerName ?? '';
        _walletTypeController.text = settings.walletType ?? '';
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _save() async {
    if (!_payOnDelivery && !_payWallet) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('فعّل طريقة دفع واحدة على الأقل')),
      );
      return;
    }

    if (_payWallet) {
      if (_walletNumberController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('رقم المحفظة مطلوب')),
        );
        return;
      }
      if (_walletOwnerController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('اسم صاحب المحفظة مطلوب')),
        );
        return;
      }
    }

    setState(() => _saving = true);
    try {
      await _api.savePaymentMethods(
        payOnDelivery: _payOnDelivery,
        payWallet: _payWallet,
        walletNumber: _payWallet ? _walletNumberController.text.trim() : null,
        walletOwnerName: _payWallet ? _walletOwnerController.text.trim() : null,
        walletType: _payWallet ? _walletTypeController.text.trim() : null,
      );
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم حفظ طرق الدفع')),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  String get _maskedPreview {
    final name = _walletOwnerController.text.trim();
    if (name.isEmpty) return '—';
    return MerchantPaymentSettings.maskOwnerName(name);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('طرق الدفع'),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _errorView()
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    const Text(
                      'حدد طرق الدفع المتاحة لعملائك',
                      style: TextStyle(color: AuthTheme.textMuted),
                    ),
                    const SizedBox(height: 16),
                    _methodCard(
                      title: 'دفع عند الاستلام',
                      subtitle: 'يدفع العميل عند استلام الطلب',
                      icon: Icons.delivery_dining,
                      value: _payOnDelivery,
                      onChanged: (v) => setState(() => _payOnDelivery = v),
                    ),
                    const SizedBox(height: 10),
                    _methodCard(
                      title: 'محفظة إلكترونية',
                      subtitle: 'تحويل على محفظتك مع رفع صورة إثبات',
                      icon: Icons.account_balance_wallet,
                      value: _payWallet,
                      onChanged: (v) => setState(() => _payWallet = v),
                    ),
                    if (_payWallet) ...[
                      const SizedBox(height: 16),
                      _walletFields(),
                    ],
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AuthTheme.primary,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: _saving ? null : _save,
                        child: _saving
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('حفظ طرق الدفع'),
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _errorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _load, child: const Text('إعادة المحاولة')),
          ],
        ),
      ),
    );
  }

  Widget _methodCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Card(
      child: SwitchListTile(
        secondary: Icon(icon, color: AuthTheme.primary),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
        subtitle: Text(subtitle),
        value: value,
        activeThumbColor: AuthTheme.primary,
        onChanged: onChanged,
      ),
    );
  }

  Widget _walletFields() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'بيانات المحفظة الإلكترونية',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _walletNumberController,
              keyboardType: TextInputType.phone,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: 'رقم المحفظة *',
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _walletOwnerController,
              decoration: const InputDecoration(
                labelText: 'اسم صاحب المحفظة (الاسم الكامل) *',
                hintText: 'مثال: محمد أحمد علي',
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 6),
            Text(
              'سيظهر للعميل بصيغة: $_maskedPreview',
              style: const TextStyle(fontSize: 12, color: AuthTheme.textMuted),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _walletTypeController,
              decoration: const InputDecoration(
                labelText: 'نوع المحفظة (اختياري)',
                hintText: 'فودافون كاش، اتصالات كاش، أورانج كاش...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
