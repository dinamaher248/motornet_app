import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:motorent/models/local_service_models.dart';
import 'package:motorent/pages/map_page.dart';
import 'package:motorent/services/google_maps_service.dart';
import 'package:motorent/services/local_service_api.dart';
import 'package:motorent/widgets/auth/auth_shell.dart';
import 'package:motorent/widgets/auth/auth_theme.dart';

class ServiceOrderConfirmPage extends StatefulWidget {
  final MerchantDetail merchant;
  final MerchantProductItem product;
  final String? distanceLabel;

  const ServiceOrderConfirmPage({
    super.key,
    required this.merchant,
    required this.product,
    this.distanceLabel,
  });

  @override
  State<ServiceOrderConfirmPage> createState() =>
      _ServiceOrderConfirmPageState();
}

class _ServiceOrderConfirmPageState extends State<ServiceOrderConfirmPage> {
  final _api = LocalServiceApi();
  final _notesController = TextEditingController();
  final _addressController = TextEditingController();
  final _detailsController = TextEditingController();

  int _quantity = 1;
  String? _paymentMethod;
  String? _paymentProofPath;
  double? _deliveryLat;
  double? _deliveryLng;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final methods = PaymentMethodOption.dedupe(widget.merchant.paymentMethods);
    if (methods.isNotEmpty) {
      _paymentMethod = methods.first.key;
    }
    _useCurrentLocation();
  }

  List<PaymentMethodOption> get _methods =>
      PaymentMethodOption.dedupe(widget.merchant.paymentMethods);

  String get _distanceText {
    final fromProp = (widget.distanceLabel ?? '').trim();
    if (fromProp.isNotEmpty && !fromProp.contains('غير')) return fromProp;
    final sLat = widget.merchant.lat;
    final sLng = widget.merchant.lng;
    final uLat = _deliveryLat;
    final uLng = _deliveryLng;
    if (sLat == null || sLng == null || (sLat == 0 && sLng == 0)) {
      return 'المتجر لم يحدد موقعه بعد';
    }
    if (uLat == null || uLng == null) {
      return 'اضغط «استخدام موقعي الحالي» لحساب المسافة';
    }
    final meters = Geolocator.distanceBetween(uLat, uLng, sLat, sLng);
    if (meters < 1000) return '${meters.round()} م';
    return '${(meters / 1000).toStringAsFixed(1)} كم';
  }

  @override
  void dispose() {
    _notesController.dispose();
    _addressController.dispose();
    _detailsController.dispose();
    super.dispose();
  }

  double get _total => widget.product.price * _quantity;

  bool get _needsWalletProof => _paymentMethod == 'wallet';

  bool get _canSubmit {
    if (_addressController.text.trim().isEmpty) return false;
    if (_detailsController.text.trim().isEmpty) return false;
    if (_deliveryLat == null || _deliveryLng == null) return false;
    if (_paymentMethod == null) return false;
    if (_needsWalletProof && (_paymentProofPath == null || _paymentProofPath!.isEmpty)) {
      return false;
    }
    return true;
  }

  Future<void> _pickFromMap() async {
    final initial = (_deliveryLat != null && _deliveryLng != null)
        ? LatLng(_deliveryLat!, _deliveryLng!)
        : null;
    final result = await Navigator.push<MapLocationResult>(
      context,
      MaterialPageRoute(
        builder: (_) => MapPage(
          initialPoint: initial,
          title: 'تحديد عنوان التوصيل',
        ),
      ),
    );
    if (result == null || !mounted) return;
    setState(() {
      _deliveryLat = result.point.latitude;
      _deliveryLng = result.point.longitude;
      _addressController.text = result.address;
    });
  }

  Future<void> _useCurrentLocation() async {
    try {
      final perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        await Geolocator.requestPermission();
      }
      final pos = await Geolocator.getCurrentPosition();
      setState(() {
        _deliveryLat = pos.latitude;
        _deliveryLng = pos.longitude;
        if (_addressController.text.trim().isEmpty) {
          _addressController.text =
              'موقعي الحالي (${pos.latitude.toStringAsFixed(4)}, ${pos.longitude.toStringAsFixed(4)})';
        }
      });
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذر تحديد الموقع')),
      );
    }
  }

  Future<void> _pickProof() async {
    final file = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (file == null) return;
    setState(() => _paymentProofPath = file.path);
  }

  Future<void> _submit() async {
    if (!_canSubmit) return;
    setState(() => _isSubmitting = true);
    try {
      final order = await _api.placeOrder(
        merchantId: widget.merchant.id,
        productId: widget.product.id,
        quantity: _quantity,
        deliveryAddress: _addressController.text.trim(),
        deliveryDetails: _detailsController.text.trim(),
        deliveryLat: _deliveryLat,
        deliveryLng: _deliveryLng,
        paymentMethod: _paymentMethod!,
        notes: _notesController.text.trim(),
        paymentProofPath: _paymentProofPath,
      );
      if (!mounted) return;
      Navigator.pop(context);
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            order.status == 'awaiting_payment_review'
                ? 'تم إرسال الطلب وبانتظار مراجعة الدفع'
                : 'تم تأكيد الطلب بنجاح',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('تأكيد الطلب')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _summaryCard(),
          const SizedBox(height: 14),
          _quantitySection(),
          const SizedBox(height: 14),
          TextField(
            controller: _notesController,
            decoration: const InputDecoration(
              labelText: 'ملاحظات على الطلب (اختياري)',
              hintText: 'مثال: بدون شطة، زيادة صوص',
              border: OutlineInputBorder(),
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _addressController,
            readOnly: true,
            decoration: const InputDecoration(
              labelText: 'عنوان التوصيل *',
              hintText: 'حدّد الموقع من الخريطة',
              border: OutlineInputBorder(),
              suffixIcon: Icon(Icons.place_outlined),
            ),
            onTap: _pickFromMap,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _useCurrentLocation,
                  icon: const Icon(Icons.my_location),
                  label: const Text('موقعي الحالي'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _pickFromMap,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AuthTheme.primary,
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.map_outlined),
                  label: const Text('تحديد من الخريطة'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _detailsController,
            decoration: const InputDecoration(
              labelText: 'العنوان التفصيلي *',
              hintText: 'الشارع، رقم العمارة، الدور، علامة مميزة',
              border: OutlineInputBorder(),
            ),
            onChanged: (_) => setState(() {}),
          ),
          if (_detailsController.text.trim().isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 6),
              child: Text(
                'يجب كتابة العنوان التفصيلي قبل تأكيد الطلب',
                style: TextStyle(color: Colors.red, fontSize: 12),
              ),
            ),
          const SizedBox(height: 14),
          const Text('طريقة الدفع',
              style: TextStyle(fontWeight: FontWeight.w700)),
          ..._methods.map((method) {
            return RadioListTile<String>(
              value: method.key,
              groupValue: _paymentMethod,
              title: Text(method.label),
              onChanged: (v) => setState(() => _paymentMethod = v),
            );
          }),
          if (_needsWalletProof) ...[
            const SizedBox(height: 8),
            _walletSection(),
          ],
          const SizedBox(height: 20),
          AuthPrimaryButton(
            label: 'تأكيد الطلب',
            isLoading: _isSubmitting,
            onPressed: _canSubmit && !_isSubmitting ? _submit : null,
          ),
        ],
      ),
    );
  }

  Widget _walletSection() {
    final wallet = widget.merchant.walletNumber ?? '';
    final owner = widget.merchant.walletOwnerDisplay ?? '';
    final type = widget.merchant.walletType ?? '';
    return Card(
      color: AuthTheme.primary.withOpacity(0.06),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('محفظة إلكترونية',
                style: TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text('رقم محفظة المتجر: $wallet'),
            if (owner.isNotEmpty) Text('اسم صاحب المحفظة: $owner'),
            if (type.isNotEmpty) Text('نوع المحفظة: $type'),
            Text('قيمة الطلب: $_total ج.م'),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: wallet.isEmpty
                        ? null
                        : () {
                            Clipboard.setData(ClipboardData(text: wallet));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('تم نسخ الرقم')),
                            );
                          },
                    icon: const Icon(Icons.copy),
                    label: const Text('نسخ الرقم'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickProof,
                    icon: const Icon(Icons.upload_file),
                    label: Text(
                      _paymentProofPath == null
                          ? 'رفع صورة التحويل'
                          : 'تم رفع الصورة',
                    ),
                  ),
                ),
              ],
            ),
            if (_paymentProofPath == null)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  'يجب رفع صورة التحويل قبل تأكيد الطلب',
                  style: TextStyle(color: Colors.red, fontSize: 12),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _summaryCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _row('اسم المتجر', widget.merchant.name),
            _row('المنتج', widget.product.name),
            _row('السعر', '${widget.product.price} ج.م'),
            if ((widget.product.description ?? '').isNotEmpty)
              _row('الوصف', widget.product.description!),
            _row('المسافة', _distanceText),
            _row('تكلفة التوصيل', 'تُحسب بالاتفاق مع صاحب النشاط'),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8E1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFFE082)),
              ),
              child: const Text(
                'تكلفة التوصيل ليست ثابتة — بعد قبول الطلب يتواصل صاحب النشاط معك لتحديدها بالاتفاق.',
                style: TextStyle(
                  fontSize: 12,
                  height: 1.45,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF8D6E00),
                ),
              ),
            ),
            const SizedBox(height: 8),
            _row(
              'طرق الدفع المتاحة',
              _methods.map((e) => e.label).join(' / '),
            ),
          ],
        ),
      ),
    );
  }

  Widget _quantitySection() {
    return Row(
      children: [
        const Text('الكمية', style: TextStyle(fontWeight: FontWeight.w700)),
        const Spacer(),
        IconButton(
          onPressed: _quantity > 1 ? () => setState(() => _quantity--) : null,
          icon: const Icon(Icons.remove_circle_outline),
        ),
        Text('$_quantity', style: const TextStyle(fontSize: 18)),
        IconButton(
          onPressed: () => setState(() => _quantity++),
          icon: const Icon(Icons.add_circle_outline),
        ),
      ],
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label,
                style: const TextStyle(color: AuthTheme.textMuted, fontSize: 12)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}
