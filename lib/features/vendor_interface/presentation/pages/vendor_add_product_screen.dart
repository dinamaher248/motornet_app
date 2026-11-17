import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:motorent/data/local/auth_prefs.dart';
import 'package:motorent/data/remote/url_api.dart';
import 'package:motorent/features/vendor_interface/domain/entities/vendor_entities.dart';
import 'package:motorent/features/vendor_interface/presentation/bloc/vendor_products_bloc.dart';
import 'package:motorent/widgets/auth/auth_theme.dart';

class VendorAddProductScreen extends StatefulWidget {
  final VendorProduct? product;

  const VendorAddProductScreen({super.key, this.product});

  bool get isEdit => product != null;

  @override
  State<VendorAddProductScreen> createState() => _VendorAddProductScreenState();
}

class _VendorAddProductScreenState extends State<VendorAddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String? _imagePath;
  String? _existingImage;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    if (p != null) {
      _nameCtrl.text = p.name;
      _priceCtrl.text = p.price.toStringAsFixed(0);
      _descCtrl.text = p.description ?? '';
      _existingImage = p.image;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _priceCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1400,
    );
    if (file == null) return;
    setState(() => _imagePath = file.path);
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final isPhotoMode = AuthPrefs.isVendorBookingsMode;
    // الصورة مطلوبة في «المنتجات» (الطلبات) فقط — اختيارية في «صور النشاط».
    if (!isPhotoMode && !widget.isEdit && _imagePath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('صورة المنتج مطلوبة')),
      );
      return;
    }
    // لا يوجد حقل سعر في «صور النشاط»؛ قيمة افتراضية ثابتة غير ظاهرة للمستخدم.
    final price = isPhotoMode
        ? 1.0
        : (double.tryParse(_priceCtrl.text.trim()) ?? 0);
    if (!isPhotoMode && (price <= 0)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('أدخل سعراً صحيحاً')),
      );
      return;
    }

    final name = _nameCtrl.text.trim().isEmpty
        ? (isPhotoMode ? 'صورة النشاط' : '')
        : _nameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('اسم المنتج مطلوب')),
      );
      return;
    }

    if (widget.isEdit) {
      context.read<VendorProductsBloc>().add(
            UpdateVendorProductEvent(
              UpdateVendorProductParams(
                productId: widget.product!.id,
                name: name,
                price: price,
                description: _descCtrl.text.trim().isEmpty
                    ? null
                    : _descCtrl.text.trim(),
                imagePath: _imagePath,
              ),
            ),
          );
    } else {
      context.read<VendorProductsBloc>().add(
            CreateVendorProductEvent(
              CreateVendorProductParams(
                name: name,
                price: price,
                imagePath: _imagePath,
                description: _descCtrl.text.trim().isEmpty
                    ? null
                    : _descCtrl.text.trim(),
              ),
            ),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final existingUrl = resolveStorageImageUrl(_existingImage);
    final isPhotoMode = AuthPrefs.isVendorBookingsMode;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isEdit
              ? (isPhotoMode ? 'تعديل الصورة' : 'تعديل المنتج')
              : (isPhotoMode
                  ? 'إضافة صور للنشاط الخاص بك'
                  : 'إضافة منتج'),
          style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
      ),
      body: BlocConsumer<VendorProductsBloc, VendorProductsState>(
        listener: (context, state) {
          if (state.status == VendorProductsStatus.created ||
              state.status == VendorProductsStatus.updated) {
            Navigator.pop(context, true);
          } else if (state.status == VendorProductsStatus.failure &&
              state.message != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message!)),
            );
          }
        },
        builder: (context, state) {
          final busy = state.status == VendorProductsStatus.creating ||
              state.status == VendorProductsStatus.updating;
          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                InkWell(
                  onTap: busy ? null : _pickImage,
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    height: 160,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AuthTheme.fieldBorder),
                      color: Colors.white,
                    ),
                    child: _imagePath != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: Image.file(
                              File(_imagePath!),
                              fit: BoxFit.cover,
                              width: double.infinity,
                            ),
                          )
                        : existingUrl.isNotEmpty
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(14),
                                child: Image.network(
                                  existingUrl,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                ),
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.add_photo_alternate_outlined,
                                      size: 40, color: AuthTheme.textMuted),
                                  const SizedBox(height: 8),
                                  Text(
                                    isPhotoMode
                                        ? 'صورة النشاط (اختيارية)'
                                        : 'صورة المنتج (مطلوبة)',
                                    style: const TextStyle(
                                      fontFamily: 'Cairo',
                                      color: AuthTheme.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                  ),
                ),
                if (widget.isEdit)
                  const Padding(
                    padding: EdgeInsets.only(top: 6),
                    child: Text(
                      'اضغط لتغيير الصورة (اختياري)',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 12,
                        color: AuthTheme.textMuted,
                      ),
                    ),
                  ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _nameCtrl,
                  decoration: InputDecoration(
                    labelText: isPhotoMode
                        ? 'عنوان رئيسي (اختياري)'
                        : 'اسم المنتج',
                    border: const OutlineInputBorder(),
                  ),
                  validator: (v) {
                    if (isPhotoMode) return null;
                    return (v == null || v.trim().isEmpty) ? 'مطلوب' : null;
                  },
                ),
                if (!isPhotoMode) ...[
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _priceCtrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'السعر (ج.م)',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'مطلوب' : null,
                  ),
                ],
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'الوصف (اختياري)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: busy ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AuthTheme.primary,
                      foregroundColor: Colors.white,
                    ),
                    child: busy
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.4,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            widget.isEdit
                                ? 'حفظ التعديلات'
                                : (isPhotoMode
                                    ? 'حفظ الصورة'
                                    : 'حفظ المنتج'),
                            style: const TextStyle(
                              fontFamily: 'Cairo',
                              fontWeight: FontWeight.w800,
                            ),
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
}
