import 'package:flutter/material.dart';
import 'package:motorent/models/merchant_owner_models.dart';
import 'package:motorent/pages/merchant/merchant_order_detail_page.dart';
import 'package:motorent/services/merchant_owner_api.dart';
import 'package:motorent/widgets/auth/auth_theme.dart';

class MerchantOrdersPage extends StatefulWidget {
  const MerchantOrdersPage({super.key});

  @override
  State<MerchantOrdersPage> createState() => _MerchantOrdersPageState();
}

class _MerchantOrdersPageState extends State<MerchantOrdersPage> {
  final _api = MerchantOwnerApi();
  bool _loading = true;
  String? _error;
  MerchantOrdersPayload? _payload;

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
      final payload = await _api.fetchOrders();
      if (!mounted) return;
      setState(() {
        _payload = payload;
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

  Future<void> _openOrder(MerchantServiceOrder order) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => MerchantOrderDetailPage(order: order),
      ),
    );
    if (changed == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('الطلبات'),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _errorView()
              : RefreshIndicator(
                  onRefresh: _load,
                  child: _buildList(_payload!),
                ),
    );
  }

  Widget _errorView() {
    return ListView(
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.2),
        Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: _load, child: const Text('إعادة المحاولة')),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildList(MerchantOrdersPayload payload) {
    if (payload.orders.isEmpty) {
      return ListView(
        children: const [
          SizedBox(height: 120),
          Center(
            child: Text(
              'لا توجد طلبات بعد',
              style: TextStyle(color: AuthTheme.textMuted),
            ),
          ),
        ],
      );
    }

    final pending = payload.orders.where((o) => o.isPending).toList();
    final inProgress = payload.orders.where((o) => o.isInProgress).toList();
    final closed = payload.orders.where((o) => o.isClosed).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      children: [
        if (payload.pendingCount > 0)
          Card(
            color: const Color(0xFFFFF8E1),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  const Icon(Icons.pending_actions, color: Colors.orange),
                  const SizedBox(width: 10),
                  Text(
                    '${payload.pendingCount} طلب بانتظار إجراءك',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ),
        if (pending.isNotEmpty) ...[
          const SizedBox(height: 8),
          const Text('بانتظار المراجعة',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
          const SizedBox(height: 8),
          ...pending.map(_orderCard),
        ],
        if (inProgress.isNotEmpty) ...[
          const SizedBox(height: 16),
          const Text('جاري التنفيذ',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
          const SizedBox(height: 4),
          const Text(
            'بعد موافقتك وحتى تسليم السائق للعميل',
            style: TextStyle(fontSize: 12, color: AuthTheme.textMuted),
          ),
          const SizedBox(height: 8),
          ...inProgress.map(_orderCard),
        ],
        if (closed.isNotEmpty) ...[
          const SizedBox(height: 16),
          const Text('مكتملة / مغلقة',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
          const SizedBox(height: 8),
          ...closed.map(_orderCard),
        ],
      ],
    );
  }

  Widget _orderCard(MerchantServiceOrder order) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: () => _openOrder(order),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      order.productName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  _statusChip(order),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                '${order.totalPrice.toStringAsFixed(0)} ج.م • ${order.paymentMethodLabel}',
                style: const TextStyle(color: AuthTheme.primary, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(
                'العميل: ${order.customer.name}',
                style: const TextStyle(fontSize: 13),
              ),
              Text(
                order.deliveryAddress,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12, color: AuthTheme.textMuted),
              ),
              if (order.createdAt != null)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    order.createdAt!,
                    style: const TextStyle(fontSize: 11, color: AuthTheme.textMuted),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusChip(MerchantServiceOrder order) {
    Color bg;
    Color fg;
    if (order.isPending) {
      bg = Colors.orange.shade50;
      fg = Colors.orange.shade800;
    } else if (order.status == 'merchant_rejected' ||
        order.status == 'cancelled' ||
        order.status == 'offer_unavailable' ||
        order.status == 'offer_rejected') {
      bg = Colors.red.shade50;
      fg = Colors.red.shade800;
    } else if (order.isCompleted) {
      bg = Colors.green.shade50;
      fg = Colors.green.shade800;
    } else {
      bg = Colors.blue.shade50;
      fg = Colors.blue.shade800;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        order.statusLabel,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: fg),
      ),
    );
  }
}
