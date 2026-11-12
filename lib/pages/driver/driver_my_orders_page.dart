import 'package:flutter/material.dart';
import 'package:motorent/models/driver_models.dart';
import 'package:motorent/services/driver_api.dart';
import 'package:motorent/widgets/auth/auth_theme.dart';

class DriverMyOrdersPage extends StatefulWidget {
  const DriverMyOrdersPage({super.key});

  @override
  State<DriverMyOrdersPage> createState() => _DriverMyOrdersPageState();
}

class _DriverMyOrdersPageState extends State<DriverMyOrdersPage> {
  final _api = DriverApi();
  List<DriverCompletedOrder> _orders = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final orders = await _api.fetchMyCompletedOrders();
      if (!mounted) return;
      setState(() {
        _orders = orders;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('طلباتي'),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: _orders.isEmpty
                  ? ListView(
                      children: const [
                        SizedBox(height: 120),
                        Center(
                          child: Text(
                            'لا توجد طلبات مكتملة بعد',
                            style: TextStyle(color: AuthTheme.textMuted),
                          ),
                        ),
                      ],
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(14),
                      itemCount: _orders.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final o = _orders[index];
                        return Card(
                          child: ListTile(
                            title: Text(o.description ?? 'طلب'),
                            subtitle: Text(
                              'من: ${o.pickLoc ?? '-'}\nإلى: ${o.targetLoc ?? '-'}\n${o.completedAt ?? ''}',
                            ),
                            trailing: o.amount != null
                                ? Text('${o.amount} ج.م')
                                : null,
                            onTap: () {
                              showModalBottomSheet(
                                context: context,
                                builder: (_) => Padding(
                                  padding: const EdgeInsets.all(20),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('تفاصيل الطلب',
                                          style: TextStyle(
                                              fontWeight: FontWeight.w800,
                                              fontSize: 16)),
                                      const SizedBox(height: 10),
                                      Text('من: ${o.pickLoc ?? '-'}'),
                                      Text('إلى: ${o.targetLoc ?? '-'}'),
                                      Text('الوصف: ${o.description ?? '-'}'),
                                      if (o.amount != null)
                                        Text('المبلغ: ${o.amount} ج.م'),
                                      Text('التاريخ: ${o.completedAt ?? '-'}'),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
