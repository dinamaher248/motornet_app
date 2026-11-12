import 'package:flutter/material.dart';
import 'package:motorent/models/local_service_models.dart';
import 'package:motorent/pages/services/customer_service_order_detail_page.dart';
import 'package:motorent/services/local_service_api.dart';
import 'package:motorent/widgets/auth/auth_theme.dart';

class MyServiceOrdersPage extends StatefulWidget {
  const MyServiceOrdersPage({super.key});

  @override
  State<MyServiceOrdersPage> createState() => _MyServiceOrdersPageState();
}

class _MyServiceOrdersPageState extends State<MyServiceOrdersPage> {
  final _api = LocalServiceApi();
  List<ServiceOrderItem> _orders = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final orders = await _api.fetchMyOrders();
      if (!mounted) return;
      setState(() {
        _orders = orders;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final actionNeeded = _orders.where((o) => o.needsAction).toList();
    final inProgress = _orders.where((o) => o.isInProgress).toList();
    final closed = _orders.where((o) => o.isClosed).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('طلبات الخدمات')),
      body:
          _loading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                onRefresh: _load,
                child:
                    _orders.isEmpty
                        ? ListView(
                          children: const [
                            SizedBox(height: 120),
                            Center(child: Text('لا توجد طلبات')),
                          ],
                        )
                        : ListView(
                          padding: const EdgeInsets.fromLTRB(14, 8, 14, 24),
                          children: [
                            if (actionNeeded.isNotEmpty) ...[
                              const Text(
                                'بانتظار ردك',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 8),
                              ...actionNeeded.map(_orderCard),
                              const SizedBox(height: 12),
                            ],
                            if (inProgress.isNotEmpty) ...[
                              const Text(
                                'جاري التنفيذ',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'حتى يستلم السائق ويوصل الطلب إليك',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AuthTheme.textMuted,
                                ),
                              ),
                              const SizedBox(height: 8),
                              ...inProgress.map(_orderCard),
                              const SizedBox(height: 12),
                            ],
                            if (closed.isNotEmpty) ...[
                              const Text(
                                'مكتملة / مغلقة',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 8),
                              ...closed.map(_orderCard),
                            ],
                          ],
                        ),
              ),
    );
  }

  Widget _orderCard(ServiceOrderItem o) {
    Color chipBg;
    Color chipFg;
    if (o.needsAction) {
      chipBg = Colors.orange.shade50;
      chipFg = Colors.orange.shade800;
    } else if (o.isCompleted) {
      chipBg = Colors.green.shade50;
      chipFg = Colors.green.shade800;
    } else if (o.isClosed) {
      chipBg = Colors.red.shade50;
      chipFg = Colors.red.shade800;
    } else {
      chipBg = Colors.blue.shade50;
      chipFg = Colors.blue.shade800;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(
          o.isCustom
              ? (o.merchantName ?? 'طلب مخصص')
              : (o.merchantName ?? o.productName),
        ),
        subtitle: Text(
          o.canChooseFulfillment
              ? 'صاحب النشاط وافق على الطلب. اضغط لاختيار: استلام من الفرع أو التوصيل بواسطة المكان'
              : o.isCustom
              ? o.productName
              : '${o.productName} × ${o.quantity}',
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              o.isCustom && o.merchantOfferPrice != null
                  ? '${o.merchantOfferPrice!.toStringAsFixed(0)} ج.م'
                  : '${o.totalPrice} ج.م',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: chipBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                o.canChooseFulfillment ? 'اختر طريقة الاستلام' : o.statusLabel,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: chipFg,
                ),
              ),
            ),
          ],
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CustomerServiceOrderDetailPage(order: o),
            ),
          ).then((_) => _load());
        },
      ),
    );
  }
}
