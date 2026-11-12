import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:motorent/data/local/cache_helper.dart';
import 'package:motorent/features/services/domain/entities/service_entities.dart';
import 'package:motorent/features/services/presentation/bloc/custom_order_bloc.dart';
import 'package:motorent/features/services/services_injection.dart';
import 'package:motorent/pages/map_page.dart';
import 'package:motorent/services/google_maps_service.dart';
import 'package:motorent/widgets/auth/auth_shell.dart';
import 'package:motorent/widgets/auth/auth_theme.dart';

class CustomOrderFormScreen extends StatelessWidget {
  final Store store;

  const CustomOrderFormScreen({super.key, required this.store});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ServicesInjection.createCustomOrderBloc(),
      child: _CustomOrderFormView(store: store),
    );
  }
}

class _CustomOrderFormView extends StatefulWidget {
  final Store store;

  const _CustomOrderFormView({required this.store});

  @override
  State<_CustomOrderFormView> createState() => _CustomOrderFormViewState();
}

class _CustomOrderFormViewState extends State<_CustomOrderFormView> {
  final _requestController = TextEditingController();
  final _addressController = TextEditingController();
  final _detailsController = TextEditingController();
  final _phoneController = TextEditingController();
  final _notesController = TextEditingController();

  String? _imagePath;
  double? _deliveryLat;
  double? _deliveryLng;
  late final String _accountPhone;

  @override
  void initState() {
    super.initState();
    _accountPhone = CacheHelper.getData(key: 'phone')?.toString().trim() ?? '';
    _phoneController.text = _accountPhone;
    _requestController.addListener(_onFormChanged);
    _addressController.addListener(_onFormChanged);
    _detailsController.addListener(_onFormChanged);
  }

  void _onFormChanged() {
    if (mounted) setState(() {});
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

  bool get _hasRequestContent {
    final hasText = _requestController.text.trim().isNotEmpty;
    final hasImage = _imagePath != null && _imagePath!.isNotEmpty;
    return hasText || hasImage;
  }

  bool get _canSubmit =>
      _hasRequestContent &&
      _addressController.text.trim().isNotEmpty &&
      _detailsController.text.trim().isNotEmpty &&
      _deliveryLat != null &&
      _deliveryLng != null &&
      _accountPhone.isNotEmpty;

  Future<void> _pickImage() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('من المعرض', style: TextStyle(fontFamily: 'Cairo')),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('الكاميرا', style: TextStyle(fontFamily: 'Cairo')),
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
    if (file != null) setState(() => _imagePath = file.path);
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
      if (perm == LocationPermission.deniedForever) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('فعّل إذن الموقع من الإعدادات')),
        );
        return;
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

  void _submit() {
    if (!_canSubmit) {
      final missing = <String>[];
      if (!_hasRequestContent) missing.add('نص الطلب أو صورة');
      if (_addressController.text.trim().isEmpty ||
          _deliveryLat == null ||
          _deliveryLng == null) {
        missing.add('تحديد الموقع من الخريطة');
      }
      if (_detailsController.text.trim().isEmpty) {
        missing.add('العنوان التفصيلي');
      }
      if (_accountPhone.isEmpty) {
        missing.add('رقم الهاتف في إعدادات الحساب');
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('يجب إكمال: ${missing.join(' و ')}')),
      );
      return;
    }
    final details = _detailsController.text.trim();
    context.read<CustomOrderBloc>().add(
          SubmitCustomOrderEvent(
            SubmitCustomOrderParams(
              storeId: widget.store.id,
              requestText: _requestController.text.trim().isEmpty
                  ? null
                  : _requestController.text.trim(),
              requestImagePath: _imagePath,
              deliveryAddress: details,
              deliveryLat: _deliveryLat,
              deliveryLng: _deliveryLng,
              contactPhone: _accountPhone,
              notes: _notesController.text.trim().isEmpty
                  ? null
                  : _notesController.text.trim(),
            ),
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'اطلب أي شيء',
          style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700),
        ),
      ),
      body: BlocConsumer<CustomOrderBloc, CustomOrderState>(
        listener: (context, state) {
          if (state.status == CustomOrderStatus.submitSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  state.message ?? 'تم إرسال طلبك — بانتظار عرض من المتجر',
                ),
              ),
            );
            Navigator.pop(context);
          } else if (state.status == CustomOrderStatus.failure &&
              state.message != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message!)),
            );
          }
        },
        builder: (context, state) {
          final busy = state.isBusy;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                widget.store.name,
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _requestController,
                maxLines: 4,
                textDirection: TextDirection.rtl,
                enabled: !busy,
                decoration: InputDecoration(
                  labelText: 'اكتب طلبك',
                  hintText: 'اختياري — أو ارفع صورة',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                style: const TextStyle(fontFamily: 'Cairo'),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: busy ? null : _pickImage,
                icon: const Icon(Icons.image_outlined),
                label: Text(
                  _imagePath == null ? 'رفع صورة' : 'تم رفع الصورة ✓',
                  style: const TextStyle(fontFamily: 'Cairo'),
                ),
              ),
              if (_imagePath != null) ...[
                const SizedBox(height: 8),
                const Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    'صورة الطلب',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    File(_imagePath!),
                    height: 160,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                TextButton(
                  onPressed: busy
                      ? null
                      : () => setState(() => _imagePath = null),
                  child: const Text(
                    'إزالة الصورة',
                    style: TextStyle(fontFamily: 'Cairo', color: Colors.red),
                  ),
                ),
              ],
              const SizedBox(height: 4),
              Text(
                _hasRequestContent
                    ? 'يمكنك استخدام الكتابة أو الصورة أو الاثنين'
                    : 'يجب إدخال نص الطلب أو رفع صورة على الأقل',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 12,
                  color: _hasRequestContent
                      ? AuthTheme.textMuted
                      : Colors.orange.shade800,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _addressController,
                textDirection: TextDirection.rtl,
                readOnly: true,
                enabled: !busy,
                onTap: busy ? null : _pickFromMap,
                decoration: InputDecoration(
                  labelText: 'عنوان التوصيل *',
                  hintText: 'حدّد الموقع من الخريطة',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  suffixIcon: const Icon(Icons.place_outlined),
                ),
                style: const TextStyle(fontFamily: 'Cairo'),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: busy ? null : _useCurrentLocation,
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
                      onPressed: busy ? null : _pickFromMap,
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
                textDirection: TextDirection.rtl,
                enabled: !busy,
                decoration: InputDecoration(
                  labelText: 'العنوان التفصيلي *',
                  hintText: 'الشارع، رقم العمارة، الدور، علامة مميزة',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                style: const TextStyle(fontFamily: 'Cairo'),
              ),
              if (_detailsController.text.trim().isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 6),
                  child: Text(
                    'مطلوب: اكتب الشارع والعمارة قبل إرسال الطلب',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      color: Colors.red,
                      fontSize: 12,
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                textDirection: TextDirection.ltr,
                readOnly: true,
                enableInteractiveSelection: false,
                decoration: InputDecoration(
                  labelText: 'رقم التواصل',
                  helperText: _accountPhone.isNotEmpty
                      ? 'من إعدادات حسابك — يظهر لصاحب النشاط عند الاتصال'
                      : 'أضف رقم هاتفك من حسابي ← إعدادات الحساب',
                  helperMaxLines: 2,
                  filled: true,
                  fillColor: const Color(0xFFF5F5F5),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  suffixIcon: const Icon(Icons.lock_outline, size: 18),
                ),
                style: const TextStyle(fontFamily: 'Cairo'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _notesController,
                maxLines: 2,
                textDirection: TextDirection.rtl,
                enabled: !busy,
                decoration: InputDecoration(
                  labelText: 'ملاحظات (اختياري)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                style: const TextStyle(fontFamily: 'Cairo'),
              ),
              const SizedBox(height: 24),
              AuthPrimaryButton(
                label: 'إرسال الطلب',
                isLoading: busy,
                onPressed: _canSubmit && !busy ? _submit : null,
              ),
            ],
          );
        },
      ),
    );
  }
}
