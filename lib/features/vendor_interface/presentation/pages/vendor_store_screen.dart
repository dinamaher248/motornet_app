import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:motorent/data/local/auth_prefs.dart';
import 'package:motorent/data/remote/url_api.dart';
import 'package:motorent/features/bidding_system/presentation/pages/bidding_home_page.dart';
import 'package:motorent/features/vendor_interface/domain/entities/vendor_entities.dart';
import 'package:motorent/features/vendor_interface/presentation/bloc/vendor_store_bloc.dart';
import 'package:motorent/features/vendor_interface/vendor_interface_injection.dart';
import 'package:motorent/pages/map_page.dart';
import 'package:motorent/services/google_maps_service.dart';
import 'package:motorent/widgets/auth/auth_theme.dart';

class VendorStoreScreen extends StatelessWidget {
  const VendorStoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => VendorInterfaceInjection.createStoreBloc()
        ..add(const FetchVendorStoreEvent()),
      child: const _VendorStoreView(),
    );
  }
}

class _VendorStoreView extends StatefulWidget {
  const _VendorStoreView();

  @override
  State<_VendorStoreView> createState() => _VendorStoreViewState();
}

class _VendorStoreViewState extends State<_VendorStoreView> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _walletNumberCtrl = TextEditingController();
  final _walletOwnerCtrl = TextEditingController();
  final _walletTypeCtrl = TextEditingController();

  int? _categoryId;
  String _listingKind = 'place';
  LatLng? _location;
  String? _existingImage;
  String? _newImagePath;
  List<VendorWorkingHours> _hours = VendorWorkingHours.defaults();
  List<VendorCategory> _categories = [];
  bool _payCod = true;
  bool _payWallet = false;
  bool _seeded = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _addressCtrl.dispose();
    _phoneCtrl.dispose();
    _walletNumberCtrl.dispose();
    _walletOwnerCtrl.dispose();
    _walletTypeCtrl.dispose();
    super.dispose();
  }

  void _seed(VendorStore store) {
    if (_seeded) return;
    _nameCtrl.text = store.name;
    _addressCtrl.text = store.address;
    _phoneCtrl.text = store.phone;
    _categoryId = store.categoryId;
    final cachedSection = AuthPrefs.vendorHubSection;
    if (AuthPrefs.isVendorServicesMode || cachedSection == 'services') {
      _listingKind = 'profession';
    } else if (AuthPrefs.isVendorBookingsMode || cachedSection == 'bookings') {
      _listingKind = 'place';
    } else if (store.listingKind == 'place' &&
        store.name.isEmpty &&
        cachedSection != null &&
        cachedSection != 'services') {
      _listingKind = 'place';
    } else {
      _listingKind =
          store.listingKind == 'profession' ? 'profession' : 'place';
    }
    _existingImage = store.image;
    _categories = store.categories;
    _payCod = store.payOnDelivery;
    _payWallet = store.payWallet;
    _walletNumberCtrl.text = store.walletNumber ?? '';
    _walletOwnerCtrl.text = store.walletOwnerName ?? '';
    _walletTypeCtrl.text = store.walletType ?? '';
    if (store.workingHours.isNotEmpty) _hours = store.workingHours;
    if (store.lat != null && store.lng != null) {
      _location = LatLng(store.lat!, store.lng!);
    }
    final visible = _sectionCategories;
    if (_categoryId != null && !visible.any((c) => c.id == _categoryId)) {
      _categoryId = null;
    }
    if (_categoryId == null && visible.isNotEmpty) {
      _categoryId = visible.first.id;
    }
    _seeded = true;
  }

  List<VendorCategory> get _sectionCategories {
    final section = AuthPrefs.vendorHubSection ?? 'orders';
    final filtered =
        _categories.where((c) => c.hubSection == section).toList();
    // لو مفيش تصنيفات مطابقة للجزء المختار، نعرض الكل عشان مايتقفلش صاحب النشاط.
    if (filtered.isNotEmpty) return filtered;
    return _categories;
  }

  String get _hubSectionLabel {
    switch (AuthPrefs.vendorHubSection) {
      case 'bookings':
        return 'الحجوزات';
      case 'services':
        return 'خدمات الصنايعيه والحرفيين';
      default:
        return 'الطلبات';
    }
  }

  Future<void> _pickImage() async {
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1400,
    );
    if (file == null) return;
    setState(() => _newImagePath = file.path);
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

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (_categoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('اختر تصنيف النشاط')),
      );
      return;
    }
    if (_location == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('حدد موقع النشاط على الخريطة')),
      );
      return;
    }
    if (AuthPrefs.isVendorOrdersMode) {
      if (!_payCod && !_payWallet) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('فعّل طريقة دفع واحدة على الأقل')),
        );
        return;
      }
      if (_payWallet && _walletNumberCtrl.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('أدخل رقم المحفظة')),
        );
        return;
      }
    }

    context.read<VendorStoreBloc>().add(
          SubmitVendorStoreEvent(
            UpdateVendorStoreParams(
              categoryId: _categoryId!,
              name: _nameCtrl.text.trim(),
              address: _addressCtrl.text.trim(),
              phone: _phoneCtrl.text.trim(),
              lat: _location!.latitude,
              lng: _location!.longitude,
              workingHours: _hours,
              imagePath: _newImagePath,
              payOnDelivery: _payCod,
              payWallet: _payWallet,
              walletNumber: _payWallet ? _walletNumberCtrl.text.trim() : null,
              walletOwnerName:
                  _payWallet ? _walletOwnerCtrl.text.trim() : null,
              walletType: _payWallet ? _walletTypeCtrl.text.trim() : null,
              listingKind: _listingKind,
            ),
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(
          'بيانات النشاط',
          style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'وسائل النقل',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => Scaffold(
                    appBar: AppBar(
                      title: const Text(
                        'وسائل النقل',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      centerTitle: true,
                    ),
                    body: Container(
                      decoration: AuthTheme.screenBackground(),
                      child: const SafeArea(
                        child: SingleChildScrollView(
                          padding: EdgeInsets.fromLTRB(20, 16, 20, 24),
                          child: BiddingHomePage(embedInParent: true),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
            icon: const Icon(Icons.two_wheeler_outlined),
          ),
        ],
      ),
      body: BlocConsumer<VendorStoreBloc, VendorStoreState>(
        listener: (context, state) {
          if (state.store != null) _seed(state.store!);
          if (state.message != null && state.message!.isNotEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message!)),
            );
            if (state.status == VendorStoreStatus.saved) {
              setState(() {
                _seeded = false;
                _newImagePath = null;
              });
              context
                  .read<VendorStoreBloc>()
                  .add(const FetchVendorStoreEvent());
            }
          }
        },
        builder: (context, state) {
          if (state.status == VendorStoreStatus.loading ||
              state.status == VendorStoreStatus.initial) {
            return const Center(child: CircularProgressIndicator());
          }

          final saving = state.status == VendorStoreStatus.saving;
          final imageUrl = resolveStorageImageUrl(_existingImage);

          return Container(
            decoration: AuthTheme.screenBackground(),
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                children: [
                  Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => Scaffold(
                              appBar: AppBar(
                                title: const Text(
                                  'وسائل النقل',
                                  style: TextStyle(
                                    fontFamily: 'Cairo',
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                centerTitle: true,
                              ),
                              body: Container(
                                decoration: AuthTheme.screenBackground(),
                                child: const SafeArea(
                                  child: SingleChildScrollView(
                                    padding:
                                        EdgeInsets.fromLTRB(20, 16, 20, 24),
                                    child: BiddingHomePage(embedInParent: true),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AuthTheme.fieldBorder),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.two_wheeler_outlined,
                                color: AuthTheme.primary),
                            SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'وسائل النقل',
                                    style: TextStyle(
                                      fontFamily: 'Cairo',
                                      fontWeight: FontWeight.w800,
                                      fontSize: 15,
                                    ),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    'اطلب موتوسيكل / تروسيكل أو أي وسيلة نقل عند الحاجة',
                                    style: TextStyle(
                                      fontFamily: 'Cairo',
                                      fontSize: 12,
                                      color: AuthTheme.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(Icons.chevron_left,
                                color: AuthTheme.textMuted),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: GestureDetector(
                      onTap: saving ? null : _pickImage,
                      child: CircleAvatar(
                        radius: 48,
                        backgroundColor:
                            AuthTheme.primary.withValues(alpha: 0.12),
                        backgroundImage: _newImagePath != null
                            ? FileImage(File(_newImagePath!))
                            : (imageUrl.isNotEmpty
                                ? NetworkImage(imageUrl)
                                : null) as ImageProvider?,
                        child: _newImagePath == null && imageUrl.isEmpty
                            ? const Icon(Icons.add_a_photo,
                                color: AuthTheme.primary)
                            : null,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'صورة النشاط',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      color: AuthTheme.textMuted,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'اسم النشاط',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'مطلوب' : null,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int>(
                    key: ValueKey(
                        'cat_${AuthPrefs.vendorHubSection}_$_categoryId'),
                    initialValue: _sectionCategories.any((c) => c.id == _categoryId)
                        ? _categoryId
                        : null,
                    decoration: const InputDecoration(
                      labelText: 'التصنيف',
                      helperText:
                          'التصنيفات حسب الجزء الذي اخترته (طلبات / حجوزات / خدمات)',
                      border: OutlineInputBorder(),
                    ),
                    items: _sectionCategories
                        .map(
                          (c) => DropdownMenuItem(
                            value: c.id,
                            child: Text(c.name,
                                style: const TextStyle(fontFamily: 'Cairo')),
                          ),
                        )
                        .toList(),
                    onChanged: saving
                        ? null
                        : (v) {
                            setState(() => _categoryId = v);
                            final match = _categories
                                .where((c) => c.id == v)
                                .toList();
                            if (match.isNotEmpty) {
                              AuthPrefs.saveVendorHubSection(
                                  match.first.hubSection);
                            }
                          },
                    validator: (v) =>
                        (_categoryId == null) ? 'اختر التصنيف' : null,
                  ),
                  if (_categories.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: 6, bottom: 4),
                      child: Text(
                        'لا توجد تصنيفات مفعّلة حالياً. أضفها من لوحة الإدارة.',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 12,
                          color: AuthTheme.textMuted,
                        ),
                      ),
                    )
                  else if (_categories
                      .where((c) =>
                          c.hubSection ==
                          (AuthPrefs.vendorHubSection ?? 'orders'))
                      .isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 6, bottom: 4),
                      child: Text(
                        'لا توجد تصنيفات لقسم $_hubSectionLabel — معروضة كل التصنيفات المتاحة. اختر المناسب أو أضف تصنيفاً من لوحة الإدارة بنفس النوع.',
                        style: const TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 12,
                          color: AuthTheme.textMuted,
                        ),
                      ),
                    ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _addressCtrl,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'العنوان',
                      hintText:
                          'اكتب العنوان بالتفصيل (الشارع، العمارة، الدور...)',
                      alignLabelWithHint: true,
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'مطلوب' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _phoneCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'رقم الهاتف',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) =>
                        (v == null || v.trim().length < 9) ? 'غير صحيح' : null,
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: saving ? null : _pickLocation,
                    icon: const Icon(Icons.map_outlined),
                    label: Text(
                      _location == null
                          ? 'تحديد الموقع على الخريطة'
                          : 'تم تحديد الموقع (${_location!.latitude.toStringAsFixed(4)}, ${_location!.longitude.toStringAsFixed(4)})',
                      style: const TextStyle(fontFamily: 'Cairo'),
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (AuthPrefs.isVendorOrdersMode) ...[
                    const Text(
                      'طرق الدفع',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    SwitchListTile(
                      title: const Text('دفع عند الاستلام',
                          style: TextStyle(fontFamily: 'Cairo')),
                      value: _payCod,
                      onChanged:
                          saving ? null : (v) => setState(() => _payCod = v),
                    ),
                    SwitchListTile(
                      title: const Text('محفظة إلكترونية',
                          style: TextStyle(fontFamily: 'Cairo')),
                      value: _payWallet,
                      onChanged: saving
                          ? null
                          : (v) => setState(() => _payWallet = v),
                    ),
                    if (_payWallet) ...[
                      TextFormField(
                        controller: _walletNumberCtrl,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'رقم المحفظة',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _walletOwnerCtrl,
                        decoration: const InputDecoration(
                          labelText: 'اسم صاحب الحساب',
                          hintText: 'الاسم الأول + اختصار الثاني والثالث',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _walletTypeCtrl,
                        decoration: const InputDecoration(
                          labelText: 'نوع المحفظة (اختياري)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                  ] else
                    const SizedBox(height: 24),
                  SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: saving ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AuthTheme.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: saving
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.4,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'حفظ بيانات النشاط',
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
