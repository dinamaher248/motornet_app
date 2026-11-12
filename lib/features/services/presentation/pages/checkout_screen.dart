import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:motorent/features/services/core/utils/payment_methods_util.dart';
import 'package:motorent/features/services/domain/entities/service_entities.dart';
import 'package:motorent/features/services/presentation/bloc/service_bloc.dart';
import 'package:motorent/features/services/services_injection.dart';
import 'package:motorent/features/services/presentation/pages/customer_hub_page.dart';
import 'package:motorent/pages/map_page.dart';
import 'package:motorent/services/google_maps_service.dart';
import 'package:motorent/widgets/auth/auth_theme.dart';

class CheckoutScreen extends StatelessWidget {
  final Store store;
  final ServiceProduct product;

  const CheckoutScreen({
    super.key,
    required this.store,
    required this.product,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ServicesInjection.createBloc(),
      child: _CheckoutView(store: store, product: product),
    );
  }
}

class _CheckoutView extends StatefulWidget {
  final Store store;
  final ServiceProduct product;

  const _CheckoutView({required this.store, required this.product});

  @override
  State<_CheckoutView> createState() => _CheckoutViewState();
}

class _CheckoutViewState extends State<_CheckoutView> {
  final _notesController = TextEditingController();
  final _addressController = TextEditingController();
  final _detailsController = TextEditingController();

  int _quantity = 1;
  String _fulfillmentType = 'merchant_delivery';
  String? _paymentMethod;
  String? _receiptPath;
  double? _deliveryLat;
  double? _deliveryLng;
  bool _locating = true;
  String? _locationError;

  List<PaymentMethod> get _methods {
    final raw = widget.store.paymentMethods.isNotEmpty
        ? widget.store.paymentMethods
        : const [
            PaymentMethod(key: 'cash', label: 'دفع عند الاستلام'),
            PaymentMethod(key: 'wallet', label: 'محفظة إلكترونية'),
          ];
    return normalizePaymentMethods(raw);
  }

  String get _distanceText {
    final fromApi = (widget.store.distanceLabel ?? '').trim();
    if (fromApi.isNotEmpty &&
        fromApi != 'المسافة غير محددة' &&
        !fromApi.contains('غير محددة') &&
        !fromApi.contains('غير متاح')) {
      return fromApi;
    }

    final storeLat = widget.store.lat;
    final storeLng = widget.store.lng;
    if (storeLat == null ||
        storeLng == null ||
        (storeLat == 0 && storeLng == 0)) {
      return 'المتجر لم يحدد موقعه بعد';
    }

    final userLat = _deliveryLat;
    final userLng = _deliveryLng;
    if (userLat == null || userLng == null) {
      if (_locating) return 'جاري حساب المسافة…';
      if (_locationError != null) return _locationError!;
      return 'اضغط «استخدام موقعي الحالي» لحساب المسافة';
    }

    final meters = Geolocator.distanceBetween(
      userLat,
      userLng,
      storeLat,
      storeLng,
    );
    if (meters < 1000) {
      return '${meters.round()} م';
    }
    return '${(meters / 1000).toStringAsFixed(1)} كم';
  }

  @override
  void initState() {
    super.initState();
    if (_methods.isNotEmpty) {
      _paymentMethod = _methods.first.key;
    }
    _useCurrentLocation(silent: true);
  }

  @override
  void dispose() {
    _notesController.dispose();
    _addressController.dispose();
    _detailsController.dispose();
    super.dispose();
  }

  double get _total => widget.product.price * _quantity;

  PaymentMethod? get _selectedMethod {
    final key = _paymentMethod;
    if (key == null) return null;
    for (final m in _methods) {
      if (m.key == key) return m;
    }
    return null;
  }

  bool get _isWallet => _selectedMethod?.isWallet ?? false;

  bool get _isPickup => _fulfillmentType == 'pickup';

  bool get _canSubmit {
    if (_paymentMethod == null) return false;
    if (_isWallet && (_receiptPath == null || _receiptPath!.isEmpty)) {
      return false;
    }
    if (!_isPickup) {
      if (_addressController.text.trim().isEmpty) return false;
      if (_detailsController.text.trim().isEmpty) return false;
      if (_deliveryLat == null || _deliveryLng == null) return false;
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
      _locationError = null;
      _locating = false;
    });
  }

  Future<void> _useCurrentLocation({bool silent = false}) async {
    setState(() {
      _locating = true;
      _locationError = null;
    });
    try {
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        if (!mounted) return;
        setState(() {
          _locating = false;
          _locationError = 'يلزم السماح بالوصول للموقع لحساب المسافة';
        });
        if (!silent) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('يرجى السماح بالوصول للموقع')),
          );
        }
        return;
      }
      final pos = await Geolocator.getCurrentPosition();
      if (!mounted) return;
      setState(() {
        _deliveryLat = pos.latitude;
        _deliveryLng = pos.longitude;
        _locating = false;
        _locationError = null;
        if (_addressController.text.trim().isEmpty) {
          _addressController.text =
              'موقعي الحالي (${pos.latitude.toStringAsFixed(4)}, ${pos.longitude.toStringAsFixed(4)})';
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _locating = false;
        _locationError = 'تعذر تحديد الموقع — أعد المحاولة';
      });
      if (!silent) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذر تحديد الموقع')),
        );
      }
    }
  }

  Future<void> _pickReceipt() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('اختيار من المعرض',
                  style: TextStyle(fontFamily: 'Cairo')),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('التقاط صورة',
                  style: TextStyle(fontFamily: 'Cairo')),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;

    final file = await ImagePicker().pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 1600,
    );
    if (file == null) return;
    setState(() => _receiptPath = file.path);
  }

  void _submit() {
    if (!_canSubmit) {
      final missing = <String>[];
      if (!_isPickup) {
        if (_addressController.text.trim().isEmpty ||
            _deliveryLat == null ||
            _deliveryLng == null) {
          missing.add('تحديد الموقع من الخريطة');
        }
        if (_detailsController.text.trim().isEmpty) {
          missing.add('العنوان التفصيلي (الشارع والعمارة)');
        }
      }
      if (missing.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('يجب إكمال: ${missing.join(' و ')}')),
        );
      }
      return;
    }

    final details = _detailsController.text.trim();
    final address = _isPickup
        ? ((widget.store.address ?? '').trim().isNotEmpty
            ? widget.store.address!.trim()
            : 'استلام من المكان')
        : details;

    context.read<ServiceBloc>().add(
          SubmitServiceOrderEvent(
            CheckoutParams(
              storeId: widget.store.id,
              productId: widget.product.id,
              quantity: _quantity,
              productTotal: _total,
              notes: _notesController.text.trim().isEmpty
                  ? null
                  : _notesController.text.trim(),
              deliveryAddress: address,
              deliveryLat: _isPickup ? widget.store.lat : _deliveryLat,
              deliveryLng: _isPickup ? widget.store.lng : _deliveryLng,
              paymentMethod: _paymentMethod!,
              walletReceiptPath: _isWallet ? _receiptPath : null,
              fulfillmentType: _fulfillmentType,
            ),
          ),
        );
  }

  Future<void> _onSuccess(String message) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text(
          'تم بنجاح',
          style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w800),
        ),
        content: Text(
          message.isNotEmpty
              ? message
              : 'تم إرسال الطلب للمتجر وهو بانتظار المراجعة',
          style: const TextStyle(fontFamily: 'Cairo'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('حسناً', style: TextStyle(fontFamily: 'Cairo')),
          ),
        ],
      ),
    );
    if (!mounted) return;
    CustomerHubController.tabIndex.value = 0;
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'تأكيد الطلب',
          style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
      ),
      body: BlocConsumer<ServiceBloc, ServiceState>(
        listener: (context, state) {
          if (state is OrderSubmitSuccess) {
            _onSuccess(state.order.message);
          } else if (state is OrderSubmitError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
        },
        builder: (context, state) {
          final submitting = state is OrderSubmitting;

          return Container(
            decoration: AuthTheme.screenBackground(),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
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
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 14),
                _fulfillmentSection(submitting),
                if (!_isPickup) ...[
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
                  onTap: submitting ? null : _pickFromMap,
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed:
                            submitting ? null : () => _useCurrentLocation(),
                        icon: const Icon(Icons.my_location),
                        label: const Text(
                          'موقعي الحالي',
                          style: TextStyle(fontFamily: 'Cairo', fontSize: 13),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: submitting ? null : _pickFromMap,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AuthTheme.primary,
                          foregroundColor: Colors.white,
                        ),
                        icon: const Icon(Icons.map_outlined),
                        label: const Text(
                          'تحديد من الخريطة',
                          style: TextStyle(fontFamily: 'Cairo', fontSize: 13),
                        ),
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
                ],
                const SizedBox(height: 16),
                const Text(
                  'طريقة الدفع',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
                RadioGroup<String>(
                  groupValue: _paymentMethod,
                  onChanged: submitting
                      ? (_) {}
                      : (v) => setState(() => _paymentMethod = v),
                  child: Column(
                    children: _methods
                        .map(
                          (method) => RadioListTile<String>(
                            value: method.key,
                            title: Text(
                              method.label,
                              style: const TextStyle(fontFamily: 'Cairo'),
                            ),
                            enabled: !submitting,
                          ),
                        )
                        .toList(),
                  ),
                ),
                if (_isWallet) ...[
                  const SizedBox(height: 8),
                  _walletSection(),
                ],
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed:
                        _canSubmit && !submitting ? _submit : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AuthTheme.primary,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor:
                          AuthTheme.primary.withValues(alpha: 0.35),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: submitting
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.4,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'تأكيد الطلب',
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                  ),
                ),
                if (_isWallet && _receiptPath == null)
                  const Padding(
                    padding: EdgeInsets.only(top: 10),
                    child: Text(
                      'يجب رفع صورة التحويل قبل تأكيد الطلب',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        color: Colors.red,
                        fontSize: 12,
                      ),
                    ),
                  ),
                if (!_isPickup && _detailsController.text.trim().isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 10),
                    child: Text(
                      'يجب كتابة العنوان التفصيلي (الشارع والعمارة) قبل تأكيد الطلب',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        color: Colors.red,
                        fontSize: 12,
                      ),
                    ),
                  ),
                if (!_isPickup &&
                    (_deliveryLat == null || _deliveryLng == null))
                  const Padding(
                    padding: EdgeInsets.only(top: 6),
                    child: Text(
                      'يجب تحديد الموقع من الخريطة أو استخدام موقعك الحالي',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        color: Colors.red,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _summaryCard() {
    final payments = _methods.map((e) => e.label).join(' / ');
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AuthTheme.fieldBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _row('اسم المتجر', widget.store.name),
          _row('المنتج', widget.product.name),
          _row('السعر', '${widget.product.price.toStringAsFixed(0)} ج.م'),
          if ((widget.product.description ?? '').trim().isNotEmpty)
            _row('الوصف', widget.product.description!),
          _row('المسافة', _distanceText),
          const SizedBox(height: 8),
          _row('طرق الدفع المتاحة', payments),
        ],
      ),
    );
  }

  Widget _fulfillmentSection(bool submitting) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AuthTheme.fieldBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'طريقة الاستلام',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontWeight: FontWeight.w800,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 6),
          RadioGroup<String>(
            groupValue: _fulfillmentType,
            onChanged: submitting
                ? (_) {}
                : (v) => setState(() => _fulfillmentType = v ?? 'merchant_delivery'),
            child: Column(
              children: [
                RadioListTile<String>(
                  value: 'merchant_delivery',
                  contentPadding: EdgeInsets.zero,
                  title: const Text(
                    'توصيل بواسطة المكان',
                    style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700),
                  ),
                  subtitle: const Text(
                    'المكان يوصّل الطلب لعنوانك',
                    style: TextStyle(fontFamily: 'Cairo', fontSize: 12),
                  ),
                  enabled: !submitting,
                ),
                RadioListTile<String>(
                  value: 'pickup',
                  contentPadding: EdgeInsets.zero,
                  title: const Text(
                    'استلام من المكان',
                    style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700),
                  ),
                  subtitle: const Text(
                    'تستلم الطلب بنفسك من المتجر',
                    style: TextStyle(fontFamily: 'Cairo', fontSize: 12),
                  ),
                  enabled: !submitting,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _quantitySection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AuthTheme.fieldBorder),
      ),
      child: Row(
        children: [
          const Text(
            'الكمية',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontWeight: FontWeight.w800,
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed:
                _quantity > 1 ? () => setState(() => _quantity--) : null,
            icon: const Icon(Icons.remove_circle_outline),
          ),
          Text(
            '$_quantity',
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          IconButton(
            onPressed: () => setState(() => _quantity++),
            icon: const Icon(Icons.add_circle_outline),
          ),
        ],
      ),
    );
  }

  Widget _walletSection() {
    final wallet = widget.store.walletNumber ?? '';
    final owner = widget.store.walletOwnerDisplay ?? '';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AuthTheme.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AuthTheme.fieldBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'محفظة الكترونية',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(
                  wallet.isEmpty
                      ? 'رقم المحفظة غير متوفر'
                      : 'رقم محفظة المتجر: $wallet',
                  style: const TextStyle(fontFamily: 'Cairo'),
                ),
              ),
              IconButton(
                onPressed: wallet.isEmpty
                    ? null
                    : () {
                        Clipboard.setData(ClipboardData(text: wallet));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('تم نسخ الرقم')),
                        );
                      },
                icon: const Icon(Icons.copy),
                tooltip: 'نسخ',
              ),
            ],
          ),
          if (owner.isNotEmpty)
            Text(
              'اسم صاحب المحفظة: $owner',
              style: const TextStyle(
                fontFamily: 'Cairo',
                color: AuthTheme.textMuted,
                fontSize: 13,
              ),
            ),
          const SizedBox(height: 8),
          Text(
            'الإجمالي: ${_total.toStringAsFixed(0)} ج.م',
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontWeight: FontWeight.w800,
              fontSize: 16,
              color: AuthTheme.primaryDark,
            ),
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: _pickReceipt,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: double.infinity,
              height: 140,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _receiptPath == null
                      ? AuthTheme.fieldBorder
                      : AuthTheme.primary,
                  width: _receiptPath == null ? 1 : 1.5,
                ),
              ),
              child: _receiptPath != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        File(_receiptPath!),
                        fit: BoxFit.cover,
                        width: double.infinity,
                      ),
                    )
                  : const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_photo_alternate_outlined,
                            size: 36, color: AuthTheme.textMuted),
                        SizedBox(height: 8),
                        Text(
                          'رفع صورة التحويل',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontWeight: FontWeight.w700,
                            color: AuthTheme.textMuted,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
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
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontFamily: 'Cairo',
                color: AuthTheme.textMuted,
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
