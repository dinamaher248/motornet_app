import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:motorent/data/local/cache_helper.dart';
import 'package:motorent/models/trip_request_models.dart';
import 'package:motorent/pages/customer/trip_offers_page.dart';
import 'package:motorent/services/trip_request_service.dart';
import 'package:motorent/widgets/auth/auth_shell.dart';
import 'package:motorent/widgets/auth/auth_theme.dart';
import 'package:motorent/widgets/customer/location_field.dart';

class TripRequestFormPage extends StatefulWidget {
  final String serviceType;
  final String vehicleType;
  final String title;
  final String descriptionLabel;

  const TripRequestFormPage({
    super.key,
    required this.serviceType,
    required this.vehicleType,
    required this.title,
    required this.descriptionLabel,
  });

  @override
  State<TripRequestFormPage> createState() => _TripRequestFormPageState();
}

class _TripRequestFormPageState extends State<TripRequestFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _pickController = TextEditingController();
  final _targetController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _phoneController = TextEditingController();
  final _notesController = TextEditingController();
  final _service = TripRequestService();

  LatLng? _pickPoint;
  LatLng? _targetPoint;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final cachedPhone = CacheHelper.getData(key: 'phone')?.toString();
    if (cachedPhone != null && cachedPhone.isNotEmpty) {
      _phoneController.text = cachedPhone;
    }
  }

  @override
  void dispose() {
    _pickController.dispose();
    _targetController.dispose();
    _descriptionController.dispose();
    _phoneController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    try {
      final trip = await _service.createRequest({
        'service_type': widget.serviceType,
        'vehicle_type': widget.vehicleType,
        'pick_loc': _pickController.text.trim(),
        'target_loc': _targetController.text.trim(),
        'pick_lat': _pickPoint?.latitude,
        'pick_lng': _pickPoint?.longitude,
        'target_lat': _targetPoint?.latitude,
        'target_lng': _targetPoint?.longitude,
        'description': _descriptionController.text.trim(),
        'contact_phone': _phoneController.text.trim(),
        'notes': _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      });

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => TripOffersPage(trip: trip),
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
      appBar: AppBar(
        title: Text(widget.title),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              LocationField(
                label: 'مكان الاستلام',
                controller: _pickController,
                point: _pickPoint,
                onMapPick: () {},
                onPointChanged: (point) => setState(() => _pickPoint = point),
              ),
              const SizedBox(height: 16),
              LocationField(
                label: 'مكان التوصيل',
                controller: _targetController,
                point: _targetPoint,
                onMapPick: () {},
                onPointChanged: (point) => setState(() => _targetPoint = point),
              ),
              const SizedBox(height: 16),
              _buildField(
                label: widget.descriptionLabel,
                controller: _descriptionController,
                maxLines: 4,
                required: true,
              ),
              const SizedBox(height: 16),
              _buildField(
                label: 'رقم التواصل',
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                required: true,
              ),
              const SizedBox(height: 16),
              _buildField(
                label: 'ملاحظات إضافية (اختياري)',
                controller: _notesController,
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              AuthPrimaryButton(
                label: 'اطلب الآن',
                isLoading: _isSubmitting,
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required String label,
    required TextEditingController controller,
    int maxLines = 1,
    TextInputType? keyboardType,
    bool required = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Cairo',
            fontWeight: FontWeight.w600,
            color: AuthTheme.textDark,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFFFAFAFA),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          validator: required
              ? (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'هذا الحقل مطلوب';
                  }
                  return null;
                }
              : null,
        ),
      ],
    );
  }
}
