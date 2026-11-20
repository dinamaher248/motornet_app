import 'package:flutter/material.dart';

import 'package:motorent/data/remote/url_api.dart';

import 'package:motorent/models/merchant_owner_models.dart';

import 'package:motorent/services/merchant_owner_api.dart';

import 'package:motorent/widgets/auth/auth_theme.dart';

import 'package:motorent/widgets/rating_stars.dart';

import 'package:motorent/pages/order_tracking/active_order_tracking_page.dart';

import 'package:url_launcher/url_launcher.dart';
import 'package:motorent/features/bidding_system/presentation/pages/bidding_home_page.dart';
import 'package:motorent/features/vendor_interface/domain/entities/vendor_order_dispatch_prefill.dart';




class MerchantOrderDetailPage extends StatefulWidget {

  final MerchantServiceOrder order;



  const MerchantOrderDetailPage({super.key, required this.order});



  @override

  State<MerchantOrderDetailPage> createState() =>

      _MerchantOrderDetailPageState();

}



class _MerchantOrderDetailPageState extends State<MerchantOrderDetailPage> {

  final _api = MerchantOwnerApi();

  late MerchantServiceOrder _order;

  bool _acting = false;



  final _offerPriceController = TextEditingController();

  final _offerNotesController = TextEditingController();



  @override

  void initState() {

    super.initState();

    _order = widget.order;

  }



  @override

  void dispose() {

    _offerPriceController.dispose();

    _offerNotesController.dispose();

    super.dispose();

  }



  Future<void> _runAction(Future<MerchantServiceOrder> Function() action) async {

    setState(() => _acting = true);

    try {

      final updated = await action();

      if (!mounted) return;

      setState(() {

        _order = updated;

        _acting = false;

      });

      ScaffoldMessenger.of(context).showSnackBar(

        const SnackBar(content: Text('تم تحديث الطلب')),

      );

      if (!_order.isPending && !_order.isCustom && !_order.canDeliver) {

        Navigator.pop(context, true);

      }

    } catch (e) {

      if (!mounted) return;

      setState(() => _acting = false);

      ScaffoldMessenger.of(context).showSnackBar(

        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),

      );

    }

  }



  Future<void> _sendOffer() async {

    final priceText = _offerPriceController.text.trim();

    final notes = _offerNotesController.text.trim();

    final price = priceText.isEmpty ? null : double.tryParse(priceText);







    await _runAction(() => _api.sendCustomOffer(

          orderId: _order.id,

          merchantOfferPrice: price,

          merchantOfferNotes: notes.isEmpty ? null : notes,

        ));

  }



  /// يفتح شاشة «وسائل المواصلات / مشوار سريع» ببيانات الطلب معبأة تلقائياً:
  /// التسليم = عنوان/موقع العميل، الاستلام = عنوان المكان (قابل للتعديل).
  Future<void> _openTransport() async {
    final o = _order;
    final dropoff = VendorOrderDispatchPrefill.formatDeliveryAddress(
      o.deliveryAddress,
    );
    final pickup = (o.storeAddress ?? '').trim().isNotEmpty
        ? o.storeAddress!.trim()
        : 'موقع النشاط';
    final prefill = VendorOrderDispatchPrefill(
      orderId: o.id,
      orderType: o.orderType,
      dropoffAddress: dropoff.isNotEmpty ? dropoff : o.deliveryAddress,
      dropoffLat: o.deliveryLat,
      dropoffLng: o.deliveryLng,
      pickupAddress: pickup,
      pickupLat: o.storeLat,
      pickupLng: o.storeLng,
      customerPhone: o.customer.phone ?? o.customerContactPhone,
      orderDescription: 'توصيل طلب #${o.id}',
    );
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(
            title: const Text(
              'وسائل المواصلات / مشوار سريع',
              style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700),
            ),
            centerTitle: true,
          ),
          body: Container(
            decoration: AuthTheme.screenBackground(),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
              child: BiddingHomePage(
                embedInParent: true,
                vendorDispatch: prefill,
              ),
            ),
          ),
        ),
      ),
    );
    try {
      final fresh = await _api.fetchOrder(_order.id);
      if (mounted) setState(() => _order = fresh);
    } catch (_) {}
  }

  Future<void> _pickDriver() async {

    setState(() => _acting = true);

    try {

      final drivers = await _api.fetchAvailableDrivers(_order.id);

      if (!mounted) return;

      setState(() => _acting = false);



      if (drivers.isEmpty) {

        ScaffoldMessenger.of(context).showSnackBar(

          const SnackBar(content: Text('لا يوجد سائقون متصلون حالياً')),

        );

        return;

      }



      final selected = await showModalBottomSheet<MerchantAvailableDriver>(

        context: context,

        shape: const RoundedRectangleBorder(

          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),

        ),

        builder: (context) => ListView(

          padding: const EdgeInsets.all(16),

          children: [

            const Text(

              'اختر السائق',

              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),

            ),

            const SizedBox(height: 12),

            ...drivers.map(

              (d) => ListTile(

                leading: const Icon(Icons.delivery_dining),

                title: Text(d.name),

                subtitle: Text(d.vehicleType ?? ''),

                onTap: () => Navigator.pop(context, d),

              ),

            ),

          ],

        ),

      );



      if (selected == null) return;



      await _runAction(() => _api.assignDriver(

            orderId: _order.id,

            driverId: selected.id,

          ));

    } catch (e) {

      if (!mounted) return;

      setState(() => _acting = false);

      ScaffoldMessenger.of(context).showSnackBar(

        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),

      );

    }

  }



  Future<void> _markDelivered() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تم التسليم', style: TextStyle(fontFamily: 'Cairo')),
        content: const Text(
          'هل تم تسليم الطلب للعميل؟ سيتم إنهاء الطلب وإبلاغ العميل.',
          style: TextStyle(fontFamily: 'Cairo'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('رجوع'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('تأكيد'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await _runAction(() => _api.markOrderDelivered(_order.id));
  }

  Future<void> _markReady() async {
    await _runAction(() => _api.markOrderReady(_order.id));
    if (!mounted) return;
    // التوصيل بواسطة المكان: بعد التجهيز نفتح وسائل التوصيل مباشرة؛
    // بيانات التسليم (عنوان/موقع/هاتف العميل) تُؤخذ من الطلب نفسه على السيرفر.
    if (_order.isMerchantDelivery && _order.canAssignDriver) {
      await _openTransport();
    }
  }

  void _showProofImage(String? path) {

    final url = resolveStorageImageUrl(path);

    if (url.isEmpty) return;

    showDialog(

      context: context,

      builder: (_) => Dialog(

        child: InteractiveViewer(

          child: Image.network(url, fit: BoxFit.contain),

        ),

      ),

    );

  }



  void _callPhone(String? phone) {

    if (phone == null || phone.isEmpty) return;

    launchUrl(Uri.parse('tel:$phone'));

  }



  void _openWhatsApp(String? phone) {

    if (phone == null || phone.isEmpty) return;

    final digits = phone.replaceAll(RegExp(r'\D'), '');

    launchUrl(

      Uri.parse('https://wa.me/$digits'),

      mode: LaunchMode.externalApplication,

    );

  }



  bool get _showCustomer => _order.customer.id > 0;

  bool get _canContact => _order.canContact;




  @override

  Widget build(BuildContext context) {

    final proofUrl = resolveStorageImageUrl(_order.paymentProof);

    final customImageUrl = resolveStorageImageUrl(_order.customRequestImage);



    return Scaffold(

      appBar: AppBar(

        title: const Text('تفاصيل الطلب'),

        centerTitle: true,

      ),

      body: ListView(

        padding: const EdgeInsets.all(16),

        children: [

          _statusBanner(),

          const SizedBox(height: 12),

          if (_order.isCustom) ...[

            _sectionCard(

              title: 'تفاصيل الطلب المخصص',

              children: [

                if ((_order.customRequestText ?? '').isNotEmpty)

                  _row('الطلب', _order.customRequestText!),

                if (customImageUrl.isNotEmpty) ...[

                  const SizedBox(height: 8),

                  GestureDetector(

                    onTap: () => _showProofImage(_order.customRequestImage),

                    child: ClipRRect(

                      borderRadius: BorderRadius.circular(12),

                      child: Image.network(

                        customImageUrl,

                        height: 180,

                        width: double.infinity,

                        fit: BoxFit.cover,

                      ),

                    ),

                  ),

                ],

                _row('عنوان التوصيل', _order.deliveryAddress),

                if ((_order.notes ?? '').isNotEmpty)

                  _row('ملاحظات العميل', _order.notes!),

              ],

            ),

            if (_order.canSendOffer) ...[

              const SizedBox(height: 12),

              Container(

                padding: const EdgeInsets.all(12),

                decoration: BoxDecoration(

                  color: Colors.amber.shade50,

                  borderRadius: BorderRadius.circular(12),

                  border: Border.all(color: Colors.amber.shade200),

                ),

                child: const Text(

                  'إذا كان الطلب أو جزء منه غير متوفر، اكتب ذلك في الملاحظات. '

                  'وإذا كان الطلب غير متوفر بالكامل، اترك السعر فارغًا ثم اضغط «إرسال العرض».',

                  style: TextStyle(fontSize: 12),

                ),

              ),

              const SizedBox(height: 12),

              _sectionCard(

                title: 'إرسال العرض',

                children: [

                  TextField(

                    controller: _offerPriceController,

                    keyboardType: TextInputType.number,

                    decoration: InputDecoration(

                      labelText: 'السعر الإجمالي (ج.م)',

                      border: OutlineInputBorder(

                        borderRadius: BorderRadius.circular(12),

                      ),

                    ),

                  ),

                  const SizedBox(height: 12),

                  TextField(

                    controller: _offerNotesController,

                    maxLines: 3,

                    decoration: InputDecoration(

                      labelText: 'ملاحظات (اختياري)',

                      hintText: 'مثال: منتج غير متوفر',

                      border: OutlineInputBorder(

                        borderRadius: BorderRadius.circular(12),

                      ),

                    ),

                  ),

                  const SizedBox(height: 12),

                  _actionButton(

                    label: 'إرسال العرض',

                    color: AuthTheme.primary,

                    onPressed: _sendOffer,

                  ),

                ],

              ),

            ],

          ] else ...[

            _sectionCard(

              title: 'المنتج',

              children: [

                _row('اسم المنتج', _order.productName),

                _row('السعر', '${_order.productPrice.toStringAsFixed(0)} ج.م'),

                _row('الكمية', '${_order.quantity}'),

                _row('الإجمالي', '${_order.totalPrice.toStringAsFixed(0)} ج.م'),

                if (_order.commissionAmount != null)

                  _row('عمولة التطبيق',

                      '${_order.commissionAmount!.toStringAsFixed(2)} ج.م'),

                if (_order.productDescription != null &&

                    _order.productDescription!.isNotEmpty)

                  _row('وصف المنتج', _order.productDescription!),

              ],

            ),

          ],

          if (_showCustomer) ...[
            const SizedBox(height: 12),
            _buildCustomerSection(),
          ],

          if (!_order.isCustom) ...[

            const SizedBox(height: 12),

            _sectionCard(

              title: 'التوصيل والدفع',

              children: [

                _row('العنوان', _order.deliveryAddress),

                if (_order.deliveryDetails != null &&

                    _order.deliveryDetails!.isNotEmpty)

                  _row('تفاصيل إضافية', _order.deliveryDetails!),

                _row('طريقة الدفع', _order.paymentMethodLabel),

                if (_order.notes != null && _order.notes!.isNotEmpty)

                  _row('ملاحظات العميل', _order.notes!),

              ],

            ),

          ],

          if (_order.isWallet && proofUrl.isNotEmpty) ...[

            const SizedBox(height: 12),

            _sectionCard(

              title: 'صورة التحويل',

              children: [

                GestureDetector(

                  onTap: () => _showProofImage(_order.paymentProof),

                  child: ClipRRect(

                    borderRadius: BorderRadius.circular(12),

                    child: Image.network(

                      proofUrl,

                      height: 200,

                      width: double.infinity,

                      fit: BoxFit.cover,

                    ),

                  ),

                ),

              ],

            ),

          ],

          if (_order.invitedDriver != null && _order.invitedDriver!.isValid) ...[

            const SizedBox(height: 12),

            _sectionCard(

              title: 'السائق المُرسَل إليه',

              children: [

                _row('الاسم', _order.invitedDriver!.name),

                if (_order.invitedDriver!.phone != null)

                  _row('الهاتف', _order.invitedDriver!.phone!),

              ],

            ),

          ],

          if (_order.driver != null && _order.driver!.isValid) ...[

            const SizedBox(height: 12),

            _sectionCard(

              title: 'السائق المعيّن',

              children: [

                _row('الاسم', _order.driver!.name),

              ],

            ),

          ],

          const SizedBox(height: 20),

          if (_order.canMarkReady && (_order.isPickup || _order.isMerchantDelivery))
            _actionButton(
              label: _order.isPickup ? 'تم تجهيز الطلب' : 'تم التجهيز',
              color: Colors.green,
              onPressed: _markReady,
            ),
          if (_order.isReady && _order.isPickup) ...[
            const SizedBox(height: 8),
            _sectionCard(
              title: 'استلام من المكان',
              children: [
                const Text(
                  'تم إبلاغ العميل أن الطلب جاهز للاستلام. يمكنك الاتصال به.',
                  style: TextStyle(fontFamily: 'Cairo'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _actionButton(
              label: 'اتصال بالعميل',
              color: AuthTheme.primary,
              onPressed: () => _callPhone(
                _order.customer.phone ?? _order.customerContactPhone,
              ),
            ),
          ],
          if (_order.canDeliver && _order.isReady) ...[
            const SizedBox(height: 8),
            _actionButton(
              label: 'تم التسليم',
              color: Colors.green,
              onPressed: _markDelivered,
            ),
          ],
          if (_order.dispatched && !_order.canAssignDriver) ...[
            const SizedBox(height: 8),
            const Text(
              'تم إرسال الطلب للسائقين — بانتظار قبول سائق.',
              style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700),
            ),
          ],
          if (_order.canAssignDriver)

            _actionButton(

              label: _order.isMerchantDelivery
                  ? 'اختيار وسيلة التوصيل'
                  : 'اختيار سائق وإرسال الطلب',

              color: AuthTheme.primary,

              onPressed: _openTransport,

            ),

          if (['driver_assigned', 'handed_to_driver', 'in_delivery']
              .contains(_order.status)) ...[

            const SizedBox(height: 8),

            _actionButton(

              label: 'متابعة التنفيذ على الخريطة',

              color: AuthTheme.primary,

              onPressed: () {

                Navigator.push(

                  context,

                  MaterialPageRoute(

                    builder: (_) => ActiveOrderTrackingPage(

                      type: 'service_order',

                      id: _order.id,

                    ),

                  ),

                );

              },

            ),

          ],

          if (_order.canConfirmPayment || _order.canRejectPayment) ...[

            if (_order.canConfirmPayment)

              _actionButton(

                label: 'تأكيد استلام الدفع',

                color: Colors.green,

                onPressed: () =>

                    _runAction(() => _api.confirmPayment(_order.id)),

              ),

            if (_order.canRejectPayment) ...[

              const SizedBox(height: 8),

              _actionButton(

                label: 'لم يتم الدفع',

                color: Colors.red,

                outlined: true,

                onPressed: () =>

                    _runAction(() => _api.rejectPayment(_order.id)),

              ),

            ],

          ] else if (_order.canAccept || _order.canReject) ...[

            if (_order.canAccept)

              _actionButton(

                label: 'قبول الطلب',

                color: Colors.green,

                onPressed: () => _runAction(() => _api.acceptOrder(_order.id)),

              ),

            if (_order.canReject) ...[

              const SizedBox(height: 8),

              _actionButton(

                label: 'رفض الطلب',

                color: Colors.red,

                outlined: true,

                onPressed: () => _runAction(() => _api.rejectOrder(_order.id)),

              ),

            ],

          ],

        ],

      ),

    );

  }



  Widget _buildCustomerSection() {
    final phone = _order.customer.phone ?? _order.customerContactPhone;

    return _sectionCard(
      title: 'بيانات العميل',
      children: [
        if (_order.customer.name.isNotEmpty)
          _row('الاسم', _order.customer.name),
        const SizedBox(height: 6),
        RatingStars(
          rating: _order.customer.avgRating,
          count: _order.customer.ratingsCount,
        ),
        if (_canContact && phone != null && phone.isNotEmpty) ...[
          const SizedBox(height: 8),
          _row('الهاتف', phone, onTap: () => _callPhone(phone)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _callPhone(phone),
                  icon: const Icon(Icons.call),
                  label: const Text('اتصال'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _openWhatsApp(phone),
                  icon: const Icon(Icons.chat, color: Color(0xFF25D366)),
                  label: const Text('واتساب'),
                ),
              ),
            ],
          ),
        ] else ...[
          const SizedBox(height: 8),
          const Text(
            'التواصل يُتاح بعد قبول الطلب',
            style: TextStyle(color: AuthTheme.textMuted, fontFamily: 'Cairo'),
          ),
        ],
        if (_canContact && _order.customer.email != null)
          _row('البريد', _order.customer.email!),
        if (_order.status == 'completed' && _order.customer.id > 0) ...[
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => showRateSheet(
                context,
                title: 'قيّم العميل',
                contextType: 'service_order',
                contextId: _order.id,
                rateeUserId: _order.customer.id,
              ),
              icon: const Icon(Icons.star_outline),
              label: const Text('تقييم العميل'),
            ),
          ),
        ],
      ],
    );
  }


  Widget _statusBanner() {

    return Container(

      width: double.infinity,

      padding: const EdgeInsets.all(14),

      decoration: BoxDecoration(

        color: _order.isPending

            ? Colors.orange.shade50

            : const Color(0xFFE8F5EE),

        borderRadius: BorderRadius.circular(14),

        border: Border.all(

          color: _order.isPending ? Colors.orange : AuthTheme.primary,

        ),

      ),

      child: Column(

        crossAxisAlignment: CrossAxisAlignment.start,

        children: [

          Text(

            _order.statusLabel,

            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),

          ),

          if (_order.createdAt != null)

            Text(

              _order.createdAt!,

              style: const TextStyle(color: AuthTheme.textMuted, fontSize: 12),

            ),

        ],

      ),

    );

  }



  Widget _sectionCard({

    required String title,

    required List<Widget> children,

  }) {

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



  Widget _row(String label, String value, {VoidCallback? onTap}) {

    return Padding(

      padding: const EdgeInsets.only(bottom: 8),

      child: InkWell(

        onTap: onTap,

        child: Row(

          crossAxisAlignment: CrossAxisAlignment.start,

          children: [

            SizedBox(

              width: 110,

              child:

                  Text(label, style: const TextStyle(color: AuthTheme.textMuted)),

            ),

            Expanded(

              child: Text(

                value,

                style: TextStyle(

                  fontWeight: FontWeight.w600,

                  color: onTap != null ? AuthTheme.primary : null,

                  decoration: onTap != null ? TextDecoration.underline : null,

                ),

              ),

            ),

          ],

        ),

      ),

    );

  }



  Widget _actionButton({

    required String label,

    required Color color,

    required VoidCallback onPressed,

    bool outlined = false,

  }) {

    if (outlined) {

      return SizedBox(

        width: double.infinity,

        height: 48,

        child: OutlinedButton(

          style: OutlinedButton.styleFrom(foregroundColor: color),

          onPressed: _acting ? null : onPressed,

          child: _acting

              ? const SizedBox(

                  width: 22,

                  height: 22,

                  child: CircularProgressIndicator(strokeWidth: 2),

                )

              : Text(label),

        ),

      );

    }



    return SizedBox(

      width: double.infinity,

      height: 48,

      child: ElevatedButton(

        style: ElevatedButton.styleFrom(

          backgroundColor: color,

          foregroundColor: Colors.white,

        ),

        onPressed: _acting ? null : onPressed,

        child: _acting

            ? const SizedBox(

                width: 22,

                height: 22,

                child: CircularProgressIndicator(

                  strokeWidth: 2,

                  color: Colors.white,

                ),

              )

            : Text(label),

      ),

    );

  }

}


