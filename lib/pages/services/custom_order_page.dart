import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:motorent/data/local/cache_helper.dart';
import 'package:motorent/models/local_service_models.dart';
import 'package:motorent/pages/map_page.dart';
import 'package:motorent/services/google_maps_service.dart';
import 'package:motorent/services/local_service_api.dart';
import 'package:motorent/widgets/auth/auth_shell.dart';
import 'package:motorent/widgets/auth/auth_theme.dart';

class CustomOrderPage extends StatefulWidget {
  final MerchantDetail merchant;

  const CustomOrderPage({super.key, required this.merchant});

  @override
  State<CustomOrderPage> createState() => _CustomOrderPageState();
}

class _CustomOrderPageState extends State<CustomOrderPage> {
  final _api = LocalServiceApi();
  final _requestController = TextEditingController();
  final _addressController = TextEditingController();
  final _detailsController = TextEditingController();
  final _phoneController = TextEditingController();
  final _notesController = TextEditingController();

  String? _imagePath;
  double? _deliveryLat;
  double? _deliveryLng;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final cachedPhone = CacheHelper.getData(key: 'phone')?.toString().trim();
    if (cachedPhone != null && cachedPhone.isNotEmpty) {
      _phoneController.text = cachedPhone;
    }
  }

  @override
  void dispose() {
    _requestController.dispose();
    _addressController.dispose();
    _detailsController.dispose();
    _phoneController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  bool get _canSubmit {
    final hasText = _requestController.text.trim().isNotEmpty;
    final hasImage = _imagePath != null && _imagePath!.isNotEmpty;
    return (hasText || hasImage) &&
        _addressController.text.trim().isNotEmpty &&
        _detailsController.text.trim().isNotEmpty &&
        _deliveryLat != null &&
        _deliveryLng != null &&
        _phoneController.text.trim().isNotEmpty;
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
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      final pos = await Geolocator.getCurrentPosition();
      if (!mounted) return;
      setState(() {
        _deliveryLat = pos.latitude;
        _deliveryLng = pos.longitude;
        if (_addressController.text.trim().isEmpty) {
          _addressController.text =
              'موقعي الحالي (${pos.latitude.toStringAsFixed(4)}, ${pos.longitude.toStringAsFixed(4)})';
        }
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذر تحديد الموقع')),
      );
    }
  }

  Future<void> _pickImage() async {
    final file = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (file != null) setState(() => _imagePath = file.path);
  }

  Future<void> _submit() async {
    if (!_canSubmit) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'اكتب الطلب أو ارفع صورة، وحدّد الموقع من الخريطة، واكتب العنوان التفصيلي ورقم التواصل',
          ),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final details = _detailsController.text.trim();
      final address = '${_addressController.text.trim()} — $details';
      await _api.placeCustomOrder(
        merchantId: widget.merchant.id,
        customRequestText: _requestController.text.trim(),
        customRequestImagePath: _imagePath,
        customerContactPhone: _phoneController.text.trim(),
        deliveryAddress: address,
        deliveryLat: _deliveryLat,
        deliveryLng: _deliveryLng,
        notes: _notesController.text.trim(),
      );
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم إرسال طلبك — بانتظار عرض من المتجر')),
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
      appBar: AppBar(title: const Text('اطلب أي شيء')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            widget.merchant.name,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _requestController,
            maxLines: 4,
            textDirection: TextDirection.rtl,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              labelText: 'اكتب طلبك (اختياري)',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _pickImage,
            icon: const Icon(Icons.image_outlined),
            label: Text(
              _imagePath == null ? 'رفع صورة (اختياري)' : 'تم رفع الصورة',
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'يمكنك استخدام الكتابة أو الصورة أو الاثنين — يجب إدخال أحدهما على الأقل',
            style: TextStyle(fontSize: 12, color: AuthTheme.textMuted),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _addressController,
            textDirection: TextDirection.rtl,
            readOnly: true,
            onTap: _pickFromMap,
            decoration: InputDecoration(
              labelText: 'عنوان التوصيل *',
              hintText: 'حدّد الموقع من الخريطة',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              suffixIcon: const Icon(Icons.place_outlined),
            ),
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
            textDirection: TextDirection.rtl,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              labelText: 'العنوان التفصيلي *',
              hintText: 'الشارع، رقم العمارة، الدور، علامة مميزة',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          if (_detailsController.text.trim().isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 6),
              child: Text(
                'مطلوب: اكتب الشارع والعمارة قبل إرسال الطلب',
                style: TextStyle(color: Colors.red, fontSize: 12),
              ),
            ),
          const SizedBox(height: 12),
          TextField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            textDirection: TextDirection.ltr,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              labelText: 'رقم التواصل',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _notesController,
            maxLines: 2,
            textDirection: TextDirection.rtl,
            decoration: InputDecoration(
              labelText: 'ملاحظات (اختياري)',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 24),
          AuthPrimaryButton(
            label: 'إرسال الطلب',
            isLoading: _isSubmitting,
            onPressed: _canSubmit && !_isSubmitting ? _submit : null,
          ),
        ],
      ),
    );
  }
}
