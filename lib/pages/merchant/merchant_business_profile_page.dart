import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:motorent/data/local/auth_prefs.dart';
import 'package:motorent/models/local_service_models.dart';
import 'package:motorent/models/merchant_owner_models.dart';
import 'package:motorent/pages/map_page.dart';
import 'package:motorent/pages/merchant/merchant_payment_methods_page.dart';
import 'package:motorent/services/google_maps_service.dart';
import 'package:motorent/services/merchant_owner_api.dart';
import 'package:motorent/widgets/app_map_tiles.dart';
import 'package:motorent/widgets/auth/auth_theme.dart';
import 'package:motorent/widgets/rating_stars.dart';
import 'package:motorent/widgets/storage_network_avatar.dart';

class MerchantBusinessProfilePage extends StatefulWidget {
  const MerchantBusinessProfilePage({super.key});

  @override
  State<MerchantBusinessProfilePage> createState() =>
      _MerchantBusinessProfilePageState();
}

class _MerchantBusinessProfilePageState
    extends State<MerchantBusinessProfilePage> {
  final _api = MerchantOwnerApi();
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();

  bool _loading = true;
  bool _saving = false;
  int? _categoryId;
  LatLng? _location;
  String? _existingImage;
  String? _newImagePath;
  double _avgRating = 0;
  int _ratingsCount = 0;
  List<WorkingDayHours> _workingHours = WorkingDayHours.defaults();
  List<ServiceCategoryItem> _categories = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final payload = await _api.fetchProfile();
      if (!mounted) return;
      final merchant = payload.merchant;
      setState(() {
        _categories = payload.categories;
        if (merchant != null) {
          _nameController.text = merchant.name;
          _addressController.text = merchant.address;
          _phoneController.text = merchant.phone;
          _categoryId = merchant.categoryId;
          _existingImage = merchant.image;
          _avgRating = merchant.avgRating;
          _ratingsCount = merchant.ratingsCount;
          if (merchant.lat != null && merchant.lng != null) {
            _location = LatLng(merchant.lat!, merchant.lng!);
          }
          if (merchant.workingHours.isNotEmpty) {
            _workingHours = merchant.workingHours;
          }
        } else if (payload.categories.isNotEmpty) {
          _categoryId = payload.categories.first.id;
        }
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  Future<void> _pickImage() async {
    final file = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (file != null) setState(() => _newImagePath = file.path);
  }

  Future<void> _pickLocation() async {
    final result = await Navigator.push<MapLocationResult>(
      context,
      MaterialPageRoute(
        builder: (_) => MapPage(
          initialPoint: _location,
          title: 'موقع النشاط',
        ),
      ),
    );
    if (result == null) return;
    setState(() {
      _location = result.point;
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_categoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('برجاء اختيار القسم')),
      );
      return;
    }
    if (_location == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('برجاء تحديد الموقع على الخريطة')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final saved = await _api.saveProfile(
        categoryId: _categoryId!,
        name: _nameController.text.trim(),
        address: _addressController.text.trim(),
        phone: _phoneController.text.trim(),
        lat: _location!.latitude,
        lng: _location!.longitude,
        workingHours: _workingHours,
        imagePath: _newImagePath,
      );
      if (!mounted) return;
      setState(() {
        _saving = false;
        _existingImage = saved.image;
        _newImagePath = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم حفظ بيانات النشاط بنجاح')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('بيانات النشاط'),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (AuthPrefs.isVendorOrdersMode) ...[
                    _paymentMethodsLink(),
                    const SizedBox(height: 12),
                  ],
                  if (_avgRating > 0 || _ratingsCount > 0)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: RatingStars(
                        rating: _avgRating,
                        count: _ratingsCount,
                      ),
                    ),
                  _imageSection(),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'اسم النشاط',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'مطلوب' : null,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int>(
                    value: _categoryId,
                    decoration: const InputDecoration(
                      labelText: 'القسم',
                      border: OutlineInputBorder(),
                    ),
                    items: _categories
                        .map(
                          (c) => DropdownMenuItem(
                            value: c.id,
                            child: Text(c.name),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => _categoryId = v),
                    validator: (v) => v == null ? 'مطلوب' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _addressController,
                    decoration: InputDecoration(
                      labelText: 'العنوان',
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        onPressed: _pickLocation,
                        icon: const Icon(Icons.map_outlined),
                        tooltip: 'تحديد على الخريطة',
                      ),
                    ),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'مطلوب' : null,
                  ),
                  const SizedBox(height: 12),
                  _mapPreview(),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'رقم التواصل',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'مطلوب' : null,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'مواعيد العمل',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                  ),
                  const SizedBox(height: 8),
                  ...List.generate(_workingHours.length, (i) => _hoursRow(i)),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AuthTheme.primary,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: _saving ? null : _save,
                      child: _saving
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('حفظ بيانات النشاط'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _paymentMethodsLink() {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.payments, color: AuthTheme.primary),
        title: const Text('طرق الدفع', style: TextStyle(fontWeight: FontWeight.w800)),
        subtitle: const Text('دفع عند الاستلام / محفظة إلكترونية'),
        trailing: const Icon(Icons.chevron_left),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const MerchantPaymentMethodsPage(),
            ),
          );
        },
      ),
    );
  }

  Widget _imageSection() {
    return Center(
      child: Column(
        children: [
          GestureDetector(
            onTap: _pickImage,
            child: Stack(
              children: [
                if (_newImagePath != null)
                  CircleAvatar(
                    radius: 52,
                    backgroundImage: FileImage(File(_newImagePath!)),
                  )
                else if (_existingImage != null && _existingImage!.isNotEmpty)
                  StorageNetworkAvatar(
                    imagePath: _existingImage,
                    initial: _nameController.text.isNotEmpty
                        ? _nameController.text.characters.first
                        : 'ن',
                    size: 104,
                  )
                else
                  const CircleAvatar(
                    radius: 52,
                    backgroundColor: Color(0xFFE8F5EE),
                    child: Icon(
                      Icons.storefront,
                      size: 42,
                      color: AuthTheme.primary,
                    ),
                  ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: AuthTheme.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'صورة النشاط',
            style: TextStyle(color: AuthTheme.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _mapPreview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'الموقع على الخريطة',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            TextButton.icon(
              onPressed: _pickLocation,
              icon: const Icon(Icons.edit_location_alt),
              label: Text(_location == null ? 'تحديد' : 'تعديل'),
            ),
          ],
        ),
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: SizedBox(
            height: 160,
            child: _location == null
                ? Container(
                    color: const Color(0xFFF3F4F6),
                    alignment: Alignment.center,
                    child: const Text('لم يتم تحديد الموقع بعد'),
                  )
                : FlutterMap(
                    options: MapOptions(
                      initialCenter: _location!,
                      initialZoom: 15,
                      interactionOptions: const InteractionOptions(
                        flags: InteractiveFlag.none,
                      ),
                    ),
                    children: [
                      AppMapTiles.layer(),
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: _location!,
                            width: 40,
                            height: 40,
                            child: const Icon(
                              Icons.location_pin,
                              color: Colors.red,
                              size: 36,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
          ),
        ),
        if (_location != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              'خط العرض: ${_location!.latitude.toStringAsFixed(5)} | خط الطول: ${_location!.longitude.toStringAsFixed(5)}',
              style: const TextStyle(fontSize: 12, color: AuthTheme.textMuted),
            ),
          ),
      ],
    );
  }

  Widget _hoursRow(int index) {
    final day = _workingHours[index];
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    day.label,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                const Text('مغلق'),
                Switch(
                  value: day.isClosed,
                  onChanged: (v) {
                    setState(() {
                      _workingHours[index] = WorkingDayHours(
                        dayKey: day.dayKey,
                        label: day.label,
                        open: day.open,
                        close: day.close,
                        isClosed: v,
                      );
                    });
                  },
                ),
              ],
            ),
            if (!day.isClosed)
              Row(
                children: [
                  Expanded(
                    child: _timeField(
                      label: 'من',
                      value: day.open,
                      onChanged: (v) {
                        setState(() {
                          _workingHours[index] = WorkingDayHours(
                            dayKey: day.dayKey,
                            label: day.label,
                            open: v,
                            close: day.close,
                            isClosed: day.isClosed,
                          );
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _timeField(
                      label: 'إلى',
                      value: day.close,
                      onChanged: (v) {
                        setState(() {
                          _workingHours[index] = WorkingDayHours(
                            dayKey: day.dayKey,
                            label: day.label,
                            open: day.open,
                            close: v,
                            isClosed: day.isClosed,
                          );
                        });
                      },
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _timeField({
    required String label,
    required String value,
    required ValueChanged<String> onChanged,
  }) {
    return InkWell(
      onTap: () async {
        final parts = value.split(':');
        final initial = TimeOfDay(
          hour: int.tryParse(parts.first) ?? 9,
          minute: int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0,
        );
        final picked =
            await showTimePicker(context: context, initialTime: initial);
        if (picked != null) {
          final formatted =
              '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
          onChanged(formatted);
        }
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          isDense: true,
        ),
        child: Text(value),
      ),
    );
  }
}
