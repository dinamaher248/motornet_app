import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:motorent/data/remote/url_api.dart';
import 'package:motorent/models/merchant_owner_models.dart';
import 'package:motorent/services/merchant_owner_api.dart';
import 'package:motorent/widgets/auth/auth_theme.dart';

class MerchantProductEditPage extends StatefulWidget {
  final MerchantProductItem? product;

  const MerchantProductEditPage({super.key, this.product});

  bool get isEditing => product != null;

  @override
  State<MerchantProductEditPage> createState() =>
      _MerchantProductEditPageState();
}

class _MerchantProductEditPageState extends State<MerchantProductEditPage> {
  final _api = MerchantOwnerApi();
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _descriptionController = TextEditingController();

  bool _isActive = true;
  bool _saving = false;
  bool _deleting = false;
  String? _newImagePath;

  @override
  void initState() {
    super.initState();
    final product = widget.product;
    if (product != null) {
      _nameController.text = product.name;
      _priceController.text = product.price.toStringAsFixed(0);
      _descriptionController.text = product.description ?? '';
      _isActive = product.isActive;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final file = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (file != null) setState(() => _newImagePath = file.path);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final isNew = !widget.isEditing;
    if (isNew && _newImagePath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('صورة المنتج مطلوبة')),
      );
      return;
    }

    final price = double.tryParse(_priceController.text.trim());
    if (price == null || price <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('برجاء إدخال سعر صحيح')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      if (isNew) {
        await _api.createProduct(
          name: _nameController.text.trim(),
          price: price,
          imagePath: _newImagePath!,
          description: _descriptionController.text.trim(),
          isActive: _isActive,
        );
      } else {
        await _api.updateProduct(
          productId: widget.product!.id,
          name: _nameController.text.trim(),
          price: price,
          description: _descriptionController.text.trim(),
          isActive: _isActive,
          imagePath: _newImagePath,
        );
      }
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  Future<void> _delete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف المنتج'),
        content: const Text('هل أنت متأكد من حذف هذا المنتج؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    setState(() => _deleting = true);
    try {
      await _api.deleteProduct(widget.product!.id);
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _deleting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final existingImage = widget.product?.image;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'تعديل منتج' : 'إضافة منتج'),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _imageSection(existingImage),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'اسم المنتج *',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'مطلوب' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _priceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'السعر (ج.م) *',
                border: OutlineInputBorder(),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'مطلوب';
                final price = double.tryParse(v.trim());
                if (price == null || price <= 0) return 'سعر غير صحيح';
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'الوصف (اختياري)',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: SwitchListTile(
                title: const Text('حالة المنتج'),
                subtitle: Text(_isActive ? 'متاح' : 'غير متاح'),
                value: _isActive,
                activeThumbColor: Colors.green,
                onChanged: (v) => setState(() => _isActive = v),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AuthTheme.primary,
                  foregroundColor: Colors.white,
                ),
                onPressed: _saving || _deleting ? null : _save,
                child: _saving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(widget.isEditing ? 'حفظ التعديلات' : 'إضافة المنتج'),
              ),
            ),
            if (widget.isEditing) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                  onPressed: _saving || _deleting ? null : _delete,
                  child: _deleting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('حذف المنتج'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _imageSection(String? existingImage) {
    final imageUrl = resolveStorageImageUrl(existingImage);

    return Center(
      child: Column(
        children: [
          GestureDetector(
            onTap: _pickImage,
            child: Stack(
              children: [
                if (_newImagePath != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.file(
                      File(_newImagePath!),
                      width: 120,
                      height: 120,
                      fit: BoxFit.cover,
                    ),
                  )
                else if (imageUrl.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.network(
                      imageUrl,
                      width: 120,
                      height: 120,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _placeholder(),
                    ),
                  )
                else
                  _placeholder(),
                Positioned(
                  bottom: 4,
                  right: 4,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: AuthTheme.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.camera_alt, color: Colors.white, size: 18),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.isEditing ? 'صورة المنتج *' : 'صورة المنتج * (مطلوبة)',
            style: const TextStyle(color: AuthTheme.textMuted, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: const Icon(Icons.add_photo_alternate_outlined, size: 40, color: AuthTheme.textMuted),
    );
  }
}
