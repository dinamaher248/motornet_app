import 'package:flutter/material.dart';
import 'package:motorent/data/remote/url_api.dart';
import 'package:motorent/models/local_service_models.dart';
import 'package:motorent/services/local_service_api.dart';
import 'package:motorent/widgets/auth/auth_theme.dart';
import 'package:motorent/widgets/rating_stars.dart';
import 'package:motorent/pages/order_tracking/active_order_tracking_page.dart';
import 'package:url_launcher/url_launcher.dart';

class CustomerServiceOrderDetailPage extends StatefulWidget {
  final ServiceOrderItem order;

  const CustomerServiceOrderDetailPage({super.key, required this.order});

  @override
  State<CustomerServiceOrderDetailPage> createState() =>
      _CustomerServiceOrderDetailPageState();
}

class _CustomerServiceOrderDetailPageState
    extends State<CustomerServiceOrderDetailPage> {
  final _api = LocalServiceApi();
  late ServiceOrderItem _order;
  bool _acting = false;

  @override
  void initState() {
    super.initState();
    _order = widget.order;
    _refresh();
  }

  Future<void> _refresh() async {
    try {
      final fresh = await _api.fetchOrder(_order.id);
      if (!mounted) return;
      setState(() => _order = fresh);
    } catch (_) {}
  }

  Future<void> _accept() async {
    setState(() => _acting = true);
    try {
      final updated = await _api.acceptCustomOffer(_order.id);
      if (!mounted) return;
      setState(() {
        _order = updated;
        _acting = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('تم قبول العرض')));
    } catch (e) {
      if (!mounted) return;
      setState(() => _acting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  Future<void> _reject() async {
    setState(() => _acting = true);
    try {
      final updated = await _api.rejectCustomOffer(_order.id);
      if (!mounted) return;
      setState(() {
        _order = updated;
        _acting = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('تم رفض العرض')));
    } catch (e) {
      if (!mounted) return;
      setState(() => _acting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  Future<void> _chooseFulfillment(String type) async {
    setState(() => _acting = true);
    try {
      final updated = await _api.chooseFulfillment(
        orderId: _order.id,
        fulfillmentType: type,
      );
      if (!mounted) return;
      setState(() {
        _order = updated;
        _acting = false;
      });
      final msg =
          type == 'pickup'
              ? 'تم اختيار الاستلام من الفرع'
              : 'تم اختيار التوصيل بواسطة المكان — تُحصّل تكلفة التوصيل عند استلام الطلب';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg, style: const TextStyle(fontFamily: 'Cairo')),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _acting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  void _showImage(String? path) {
    final url = resolveStorageImageUrl(path);
    if (url.isEmpty) return;
    showDialog(
      context: context,
      builder:
          (_) => Dialog(
            child: InteractiveViewer(
              child: Image.network(url, fit: BoxFit.contain),
            ),
          ),
    );
  }

  Future<void> _callMerchant() async {
    final phone = _order.merchantPhone?.trim() ?? '';
    if (phone.isEmpty) return;
    await launchUrl(Uri.parse('tel:$phone'));
  }

  Future<void> _chatMerchant() async {
    final phone = (_order.merchantPhone ?? '').replaceAll(RegExp(r'\D'), '');
    if (phone.isEmpty) return;
    await launchUrl(
      Uri.parse('https://wa.me/$phone'),
      mode: LaunchMode.externalApplication,
    );
  }

  @override
  Widget build(BuildContext context) {
    final o = _order;
    final imageUrl = resolveStorageImageUrl(o.customRequestImage);

    return Scaffold(
      appBar: AppBar(title: const Text('تفاصيل الطلب')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AuthTheme.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  o.statusLabel,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                if (o.merchantName != null)
                  Text(
                    o.merchantName!,
                    style: const TextStyle(color: AuthTheme.textMuted),
                  ),
              ],
            ),
          ),
          if (o.status == 'completed' && o.merchantId != null) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed:
                    () => showRateSheet(
                      context,
                      title: 'قيّم صاحب النشاط',
                      contextType: 'service_order',
                      contextId: o.id,
                      rateeMerchantId: o.merchantId,
                    ),
                icon: const Icon(Icons.star_outline),
                label: const Text('تقييم صاحب النشاط'),
              ),
            ),
          ],
          if ([
            'driver_assigned',
            'handed_to_driver',
            'in_delivery',
          ].contains(o.status)) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AuthTheme.primary,
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (_) => ActiveOrderTrackingPage(
                            type: 'service_order',
                            id: o.id,
                          ),
                    ),
                  );
                },
                icon: const Icon(Icons.map_outlined),
                label: const Text('متابعة التنفيذ على الخريطة'),
              ),
            ),
          ],
          const SizedBox(height: 12),
          if (o.isCustom) ...[
            _card('طلبك', [
              if ((o.customRequestText ?? '').isNotEmpty)
                Text(o.customRequestText!),
              if (imageUrl.isNotEmpty) ...[
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () => _showImage(o.customRequestImage),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      imageUrl,
                      height: 160,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ],
              _row('عنوان التوصيل', o.deliveryAddress),
              if ((o.notes ?? '').isNotEmpty) _row('ملاحظاتك', o.notes!),
            ]),
            if (o.canContactMerchant) ...[
              const SizedBox(height: 12),
              _card('التواصل مع صاحب النشاط', [
                if ((o.merchantName ?? '').isNotEmpty)
                  _row('صاحب النشاط', o.merchantName!),
                if ((o.merchantPhone ?? '').isNotEmpty)
                  _row('الهاتف', o.merchantPhone!),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _callMerchant,
                        icon: const Icon(Icons.phone, size: 18),
                        label: const Text('اتصال'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0C9F6A),
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _chatMerchant,
                        icon: const Icon(Icons.chat_outlined, size: 18),
                        label: const Text('محادثة'),
                      ),
                    ),
                  ],
                ),
              ]),
            ],
            if (o.status == 'offer_sent' ||
                o.status == 'offer_unavailable' ||
                o.status == 'priced' ||
                o.canAcceptOffer ||
                o.canRejectOffer) ...[
              const SizedBox(height: 12),
              _card('عرض المتجر', [
                if (o.merchantOfferPrice != null && o.merchantOfferPrice! > 0)
                  _row(
                    'السعر الإجمالي',
                    '${o.merchantOfferPrice!.toStringAsFixed(0)} ج.م',
                  )
                else
                  const Text(
                    'غير متوفر حالياً',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                if ((o.merchantOfferNotes ?? '').isNotEmpty)
                  _row('ملاحظات المتجر', o.merchantOfferNotes!),
              ]),
              if ((o.canAcceptOffer || o.canRejectOffer) &&
                  o.merchantOfferPrice != null &&
                  o.merchantOfferPrice! > 0) ...[
                const SizedBox(height: 16),
                if (o.canAcceptOffer)
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: _acting ? null : _accept,
                      child:
                          _acting
                              ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                              : const Text('قبول'),
                    ),
                  ),
                if (o.canRejectOffer) ...[
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                      ),
                      onPressed: _acting ? null : _reject,
                      child: const Text('رفض'),
                    ),
                  ),
                ],
              ],
            ],
          ] else ...[
            _card('المنتج', [
              _row('الاسم', o.productName),
              _row('الإجمالي', '${o.totalPrice.toStringAsFixed(0)} ج.م'),
              _row('العنوان', o.deliveryAddress),
              if (o.fulfillmentType != 'pending')
                _row('الاستلام', o.fulfillmentLabel),
            ]),
            if (o.canChooseFulfillment) ...[
              const SizedBox(height: 14),
              _card('اختر طريقة الاستلام', [
                const Text(
                  'المتجر وافق على طلبك — اختر كيف تستلم طلبك:',
                  style: TextStyle(fontFamily: 'Cairo', height: 1.4),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed:
                        _acting ? null : () => _chooseFulfillment('pickup'),
                    icon: const Icon(Icons.storefront_outlined),
                    label: const Text(
                      'استلام من الفرع',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AuthTheme.primary,
                      foregroundColor: Colors.white,
                    ),
                    onPressed:
                        _acting
                            ? null
                            : () => _chooseFulfillment('merchant_delivery'),
                    icon: const Icon(Icons.delivery_dining_outlined),
                    label: const Text(
                      'التوصيل بواسطة المكان',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF8E1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFFFE082)),
                  ),
                  child: const Text(
                    'لو اخترت التوصيل بواسطة المكان: تُحصّل تكلفة التوصيل عند استلام الطلب',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 12,
                      height: 1.4,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF8D6E00),
                    ),
                  ),
                ),
              ]),
            ] else if (o.fulfillmentType == 'merchant_delivery') ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF8E1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFFE082)),
                ),
                child: const Text(
                  'التوصيل بواسطة المكان — تُحصّل تكلفة التوصيل عند استلام الطلب',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.w700,
                    height: 1.4,
                    color: Color(0xFF8D6E00),
                  ),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _card(String title, List<Widget> children) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 10),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(color: AuthTheme.textMuted),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
