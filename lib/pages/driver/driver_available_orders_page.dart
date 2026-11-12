import 'package:flutter/material.dart';
import 'package:motorent/data/local/cache_helper.dart';
import 'package:motorent/models/driver_models.dart';
import 'package:motorent/pages/driver/driver_order_detail_page.dart';
import 'package:motorent/services/driver_api.dart';
import 'package:motorent/widgets/auth/auth_theme.dart';

class DriverAvailableOrdersPage extends StatefulWidget {
  const DriverAvailableOrdersPage({super.key});

  @override
  State<DriverAvailableOrdersPage> createState() =>
      _DriverAvailableOrdersPageState();
}

class _DriverAvailableOrdersPageState extends State<DriverAvailableOrdersPage> {
  final _driverApi = DriverApi();
  List<DriverOrderItem> _orders = [];
  bool _isLoading = true;
  bool _isOnline = false;
  bool _updatingOnline = false;

  @override
  void initState() {
    super.initState();
    _isOnline = CacheHelper.getData(key: 'is_online') == 1 ||
        CacheHelper.getData(key: 'is_online') == true;
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final orders = await _driverApi.fetchAvailableOrders();
      if (!mounted) return;
      setState(() {
        _orders = orders;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleOnline(bool value) async {
    setState(() => _updatingOnline = true);
    try {
      await _driverApi.setOnlineStatus(value);
      await CacheHelper.saveData(key: 'is_online', value: value ? 1 : 0);
      if (!mounted) return;
      setState(() {
        _isOnline = value;
        _updatingOnline = false;
      });
      await _load();
    } catch (e) {
      if (!mounted) return;
      setState(() => _updatingOnline = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('الطلبات المتاحة'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          _onlineBanner(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _load,
                    child: !_isOnline
                        ? ListView(
                            children: const [
                              SizedBox(height: 80),
                              Center(
                                child: Text(
                                  'فعّل "متاح" لعرض الطلبات القريبة منك',
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          )
                        : _orders.isEmpty
                            ? ListView(
                                children: const [
                                  SizedBox(height: 80),
                                  Center(child: Text('لا توجد طلبات متاحة حالياً')),
                                ],
                              )
                            : ListView.separated(
                                padding: const EdgeInsets.all(12),
                                itemCount: _orders.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 8),
                                itemBuilder: (context, index) {
                                  final order = _orders[index];
                                  return _OrderBar(
                                    order: order,
                                    onTap: () async {
                                      await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              DriverOrderDetailPage(order: order),
                                        ),
                                      );
                                      _load();
                                    },
                                  );
                                },
                              ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _onlineBanner() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: _isOnline
            ? Colors.green.withOpacity(0.1)
            : Colors.grey.withOpacity(0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _isOnline ? Colors.green : Colors.grey.shade400,
        ),
      ),
      child: Row(
        children: [
          Icon(
            _isOnline ? Icons.check_circle : Icons.pause_circle,
            color: _isOnline ? Colors.green : Colors.grey,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _isOnline ? 'متاح — تظهر لك الطلبات' : 'غير متاح',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: _isOnline ? Colors.green.shade800 : Colors.grey.shade700,
              ),
            ),
          ),
          if (_updatingOnline)
            const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            Switch(
              value: _isOnline,
              activeColor: Colors.green,
              onChanged: _toggleOnline,
            ),
        ],
      ),
    );
  }
}

class _OrderBar extends StatelessWidget {
  final DriverOrderItem order;
  final VoidCallback onTap;

  const _OrderBar({required this.order, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 48,
                decoration: BoxDecoration(
                  color: order.isActive ? Colors.green : AuthTheme.primary,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.title,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    Text(
                      'من: ${order.pickLoc ?? '-'}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'إلى: ${order.targetLoc ?? '-'}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (order.distanceLabel != null)
                      Text('المسافة: ${order.distanceLabel}'),
                  ],
                ),
              ),
              const Icon(Icons.chevron_left),
            ],
          ),
        ),
      ),
    );
  }
}
