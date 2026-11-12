import 'package:flutter/material.dart';
import 'package:motorent/models/local_service_models.dart';
import 'package:motorent/services/local_service_api.dart';
import 'package:motorent/widgets/auth/auth_theme.dart';

class DriverServiceOrdersSection extends StatefulWidget {
  const DriverServiceOrdersSection({super.key});

  @override
  State<DriverServiceOrdersSection> createState() =>
      _DriverServiceOrdersSectionState();
}

class _DriverServiceOrdersSectionState extends State<DriverServiceOrdersSection> {
  final _api = LocalServiceApi();
  List<DriverServiceOrderItem> _orders = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final orders = await _api.fetchDriverOrders();
      if (!mounted) return;
      setState(() {
        _orders = orders;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _submitOffer(DriverServiceOrderItem order) async {
    final controller = TextEditingController(
      text: order.myOfferAmount?.toStringAsFixed(0) ?? '',
    );
    final amount = await showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('عرض سعر التوصيل'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'قيمة التوصيل (ج.م)'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          TextButton(
            onPressed: () {
              final value = double.tryParse(controller.text.trim());
              Navigator.pop(context, value);
            },
            child: const Text('إرسال'),
          ),
        ],
      ),
    );
    if (amount == null || amount <= 0) return;

    try {
      await _api.submitDeliveryOffer(order.id, amount);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم إرسال عرض التوصيل')),
      );
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'طلبات توصيل الخدمات',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        if (_loading)
          const Center(child: CircularProgressIndicator())
        else if (_orders.isEmpty)
          const Text('لا توجد طلبات توصيل حالياً',
              style: TextStyle(color: AuthTheme.textMuted))
        else
          ..._orders.map((order) {
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('استلام من: ${order.pickupFrom ?? '-'}',
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                    Text('توصيل إلى: ${order.deliverTo ?? '-'}'),
                    Text('المسافة: ${order.distanceLabel ?? '-'}'),
                    Text('الدفع: ${order.paymentMethodLabel ?? '-'}'),
                    if (order.myOfferAmount != null)
                      Text('عرضك: ${order.myOfferAmount} ج.م',
                          style: const TextStyle(color: Colors.green)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => _submitOffer(order),
                            child: const Text('عرض سعر'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }
}
