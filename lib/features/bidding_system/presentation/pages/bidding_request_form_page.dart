import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:latlong2/latlong.dart';
import 'package:motorent/data/local/cache_helper.dart';
import 'package:motorent/features/my_account/presentation/pages/profile_screen.dart';
import 'package:motorent/features/bidding_system/bidding_injection.dart';
import 'package:motorent/features/bidding_system/domain/entities/create_bidding_trip_params.dart';
import 'package:motorent/features/bidding_system/presentation/bloc/bidding_bloc.dart';
import 'package:motorent/features/bidding_system/presentation/pages/bidding_offers_page.dart';
import 'package:motorent/features/bidding_system/presentation/widgets/bidding_text_field.dart';
import 'package:motorent/features/vendor_interface/domain/entities/vendor_order_dispatch_prefill.dart';
import 'package:motorent/pages/route_map_page.dart';
import 'package:motorent/services/google_maps_service.dart';
import 'package:motorent/widgets/auth/auth_theme.dart';
import 'package:motorent/widgets/customer/location_field.dart';

class BiddingRequestFormPage extends StatelessWidget {
  final String vehicleType;
  final String title;
  final String descriptionLabel;
  final VendorOrderDispatchPrefill? vendorDispatch;

  const BiddingRequestFormPage({
    super.key,
    required this.vehicleType,
    required this.title,
    required this.descriptionLabel,
    this.vendorDispatch,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => BiddingInjection.createBloc(),
      child: _BiddingRequestFormView(
        vehicleType: vehicleType,
        title: title,
        descriptionLabel: descriptionLabel,
        vendorDispatch: vendorDispatch,
      ),
    );
  }
}

class _BiddingRequestFormView extends StatefulWidget {
  final String vehicleType;
  final String title;
  final String descriptionLabel;
  final VendorOrderDispatchPrefill? vendorDispatch;

  const _BiddingRequestFormView({
    required this.vehicleType,
    required this.title,
    required this.descriptionLabel,
    this.vendorDispatch,
  });

  @override
  State<_BiddingRequestFormView> createState() =>
      _BiddingRequestFormViewState();
}

class _BiddingRequestFormViewState extends State<_BiddingRequestFormView> {
  final _formKey = GlobalKey<FormState>();
  final _pickupController = TextEditingController();
  final _dropoffController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _phoneController = TextEditingController();
  final _notesController = TextEditingController();
  final _priceController = TextEditingController();
  final _pickupDetailsController = TextEditingController();
  final _dropoffDetailsController = TextEditingController();

  LatLng? _pickupPoint;
  LatLng? _dropoffPoint;
  String? _routeDistanceText;
  bool _loadingDistance = false;

  @override
  void initState() {
    super.initState();
    final prefill = widget.vendorDispatch;
    if (prefill != null) {
      _pickupController.text = prefill.pickupAddress;
      // عنوان التسليم = موقع العميل على الخريطة (إحداثيات)، والنص المكتوب = العنوان التفصيلي
      _dropoffController.text = prefill.hasDropoffPoint ? '' : prefill.dropoffAddress;
      if (prefill.hasDropoffPoint) {
        _dropoffDetailsController.text = prefill.dropoffAddress;
      }
      _descriptionController.text = prefill.orderDescription;
      if (prefill.hasPickupPoint) {
        _pickupPoint = LatLng(prefill.pickupLat!, prefill.pickupLng!);
      }
      if (prefill.hasDropoffPoint) {
        _dropoffPoint = LatLng(prefill.dropoffLat!, prefill.dropoffLng!);
      }
      if ((prefill.customerPhone ?? '').trim().isNotEmpty) {
        _phoneController.text = prefill.customerPhone!.trim();
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _resolveMissingCoordinates();
      });
    } else {
      final cachedPhone = CacheHelper.getData(key: 'phone')?.toString();
      if (cachedPhone != null && cachedPhone.isNotEmpty) {
        _phoneController.text = cachedPhone;
      }
    }
  }

  Future<void> _resolveMissingCoordinates() async {
    final prefill = widget.vendorDispatch;
    if (prefill == null) return;

    if (_dropoffPoint != null && _dropoffController.text.trim().isEmpty) {
      try {
        final addr = await GoogleMapsService.reverseGeocode(_dropoffPoint!);
        if (mounted && addr.trim().isNotEmpty) {
          setState(() => _dropoffController.text = addr);
        }
      } catch (_) {}
      if (mounted && _dropoffController.text.trim().isEmpty) {
        setState(() => _dropoffController.text = prefill.dropoffAddress);
      }
    }

    if (_dropoffPoint == null && prefill.dropoffAddress.trim().isNotEmpty) {
      final suggestions = await GoogleMapsService.autocomplete(
        prefill.dropoffAddress,
      );
      if (suggestions.isNotEmpty) {
        final details =
            await GoogleMapsService.placeDetails(suggestions.first.placeId);
        if (details != null && mounted) {
          setState(() {
            _dropoffPoint = details.point;
            if (_dropoffController.text.trim().isEmpty) {
              _dropoffController.text = details.address;
            }
          });
        }
      }
    }

    if (_pickupPoint == null && prefill.pickupAddress.trim().isNotEmpty) {
      final suggestions = await GoogleMapsService.autocomplete(
        prefill.pickupAddress,
      );
      if (suggestions.isNotEmpty) {
        final details =
            await GoogleMapsService.placeDetails(suggestions.first.placeId);
        if (details != null && mounted) {
          setState(() {
            _pickupPoint = details.point;
            if (_pickupController.text.trim().isEmpty) {
              _pickupController.text = details.address;
            }
          });
        }
      }
    }

    await _refreshDistance();
  }

  @override
  void dispose() {
    _pickupController.dispose();
    _dropoffController.dispose();
    _descriptionController.dispose();
    _phoneController.dispose();
    _notesController.dispose();
    _priceController.dispose();
    _pickupDetailsController.dispose();
    _dropoffDetailsController.dispose();
    super.dispose();
  }

  Future<void> _refreshDistance() async {
    if (_pickupPoint == null || _dropoffPoint == null) {
      setState(() => _routeDistanceText = null);
      return;
    }
    setState(() => _loadingDistance = true);
    final route = await GoogleMapsService.directions(
      _pickupPoint!,
      _dropoffPoint!,
    );
    if (!mounted) return;
    if (route != null) {
      setState(() {
        _loadingDistance = false;
        _routeDistanceText =
            '${route.distanceText} • ${route.durationText}';
      });
    } else {
      final km = GoogleMapsService.straightLineKm(
        _pickupPoint!,
        _dropoffPoint!,
      );
      setState(() {
        _loadingDistance = false;
        _routeDistanceText = '${km.toStringAsFixed(1)} كم (تقريبي)';
      });
    }
  }

  Future<void> _openRouteMap() async {
    if (_pickupPoint == null || _dropoffPoint == null) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RouteMapPage(
          origin: _pickupPoint!,
          destination: _dropoffPoint!,
          originLabel: _pickupController.text.trim(),
          destinationLabel: _dropoffController.text.trim(),
        ),
      ),
    );
  }

  String _accountPhone() {
    final cached = CacheHelper.getData(key: 'phone')?.toString().trim() ?? '';
    if (cached.isNotEmpty) return cached;
    return _phoneController.text.trim();
  }

  String _fullAddress(String mapAddress, String details) {
    final map = mapAddress.trim();
    final extra = details.trim();
    if (extra.isEmpty) return map;
    return '$map\nالعنوان التفصيلي: $extra';
  }

  Future<void> _onPhoneTap() async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          'رقم التواصل',
          style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w800),
        ),
        content: const Text(
          'رقم التواصل مربوط بحسابك، وهو اللي هيظهر للسائق عند الاتصال. يرجى تغييره من إعدادات الحساب.',
          style: TextStyle(fontFamily: 'Cairo', height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('حسناً', style: TextStyle(fontFamily: 'Cairo')),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              );
              if (!mounted) return;
              final cached =
                  CacheHelper.getData(key: 'phone')?.toString().trim() ?? '';
              if (cached.isNotEmpty) {
                setState(() => _phoneController.text = cached);
              }
            },
            child: const Text(
              'إعدادات الحساب',
              style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (_pickupPoint == null || _dropoffPoint == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'حدد موقع الاستلام وموقع التسليم من الخريطة حتى يصل الطلب للسائقين القريبين',
            style: TextStyle(fontFamily: 'Cairo'),
          ),
        ),
      );
      return;
    }

    final price = double.tryParse(_priceController.text.trim());
    if (price == null || price <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'أدخل السعر الذي تريد دفعه لهذه الرحلة',
            style: TextStyle(fontFamily: 'Cairo'),
          ),
        ),
      );
      return;
    }

    context.read<BiddingBloc>().add(
          CreateTripEvent(
            CreateBiddingTripParams(
              vehicleType: widget.vehicleType,
              pickupAddress: _fullAddress(
                _pickupController.text,
                _pickupDetailsController.text,
              ),
              pickupLat: _pickupPoint!.latitude,
              pickupLng: _pickupPoint!.longitude,
              dropoffAddress: _fullAddress(
                _dropoffController.text,
                _dropoffDetailsController.text,
              ),
              dropoffLat: _dropoffPoint!.latitude,
              dropoffLng: _dropoffPoint!.longitude,
              description: _descriptionController.text.trim(),
              phone: _accountPhone(),
              notes: widget.vendorDispatch?.linkNotes ??
                  (_notesController.text.trim().isEmpty
                      ? null
                      : _notesController.text.trim()),
              customerPrice: price,
            ),
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.title,
          style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
      ),
      body: BlocConsumer<BiddingBloc, BiddingState>(
        listener: (context, state) {
          if (state is BiddingError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          } else if (state is TripCreatedSuccess) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => BiddingOffersPage(trip: state.trip),
              ),
            );
          }
        },
        builder: (context, state) {
          final isLoading = state is BiddingLoading;

          return Container(
            decoration: AuthTheme.screenBackground(),
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
                children: [
                  if (widget.vendorDispatch != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFA5D6A7)),
                      ),
                      child: const Text(
                        'تم تعبئة موقع التسليم بعنوان العميل تلقائياً. راجع الاستلام من نشاطك ثم أكّد الطلب.',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontWeight: FontWeight.w600,
                          height: 1.45,
                          color: Color(0xFF2E7D32),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],
                  LocationField(
                    label: 'عنوان الاستلام',
                    controller: _pickupController,
                    point: _pickupPoint,
                    onPointChanged: (p) {
                      setState(() => _pickupPoint = p);
                      _refreshDistance();
                    },
                    onMapPick: () => _refreshDistance(),
                  ),
                  if (_pickupPoint == null)
                    const Padding(
                      padding: EdgeInsets.only(top: 6),
                      child: Text(
                        'مطلوب تحديد موقع الاستلام من الخريطة أو البحث',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 12,
                          color: Colors.orange,
                        ),
                      ),
                    ),
                  const SizedBox(height: 10),
                  BiddingTextField(
                    controller: _pickupDetailsController,
                    label: 'عنوان تفصيلي للاستلام',
                    hint: 'العمارة، الدور، علامة مميزة — اختياري',
                    requiredField: false,
                    maxLines: 2,
                  ),
                  const SizedBox(height: 14),
                  LocationField(
                    label: 'عنوان التسليم',
                    controller: _dropoffController,
                    point: _dropoffPoint,
                    onPointChanged: (p) {
                      setState(() => _dropoffPoint = p);
                      _refreshDistance();
                    },
                    onMapPick: () => _refreshDistance(),
                  ),
                  if (_dropoffPoint == null)
                    const Padding(
                      padding: EdgeInsets.only(top: 6),
                      child: Text(
                        'مطلوب تحديد موقع التسليم من الخريطة أو البحث',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 12,
                          color: Colors.orange,
                        ),
                      ),
                    ),
                  const SizedBox(height: 10),
                  BiddingTextField(
                    controller: _dropoffDetailsController,
                    label: 'عنوان تفصيلي للتسليم',
                    hint: 'العمارة، الدور، علامة مميزة — اختياري',
                    requiredField: false,
                    maxLines: 2,
                  ),
                  if (_pickupPoint != null && _dropoffPoint != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AuthTheme.fieldBorder),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.route, color: AuthTheme.primary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _loadingDistance
                                  ? 'جاري حساب المسافة...'
                                  : (_routeDistanceText ?? 'المسافة غير متاحة'),
                              style: const TextStyle(
                                fontFamily: 'Cairo',
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: _openRouteMap,
                            child: const Text(
                              'عرض المسار',
                              style: TextStyle(fontFamily: 'Cairo'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 14),
                  BiddingTextField(
                    controller: _descriptionController,
                    label: widget.descriptionLabel,
                    hint: 'اكتب تفاصيل الطلب بوضوح',
                    maxLines: 3,
                  ),
                  const SizedBox(height: 14),
                  BiddingTextField(
                    controller: _phoneController,
                    label: 'رقم التواصل',
                    hint: 'من حسابك',
                    keyboardType: TextInputType.phone,
                    readOnly: true,
                    onTap: _onPhoneTap,
                    suffix: const Icon(Icons.lock_outline, size: 20),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'أضف رقم الهاتف من إعدادات الحساب أولاً';
                      }
                      if (value.trim().length < 9) {
                        return 'رقم الهاتف غير صحيح';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'للتغيير: حسابي ← إعدادات الحساب',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 12,
                      color: AuthTheme.textMuted,
                    ),
                  ),
                  const SizedBox(height: 14),
                  BiddingTextField(
                    controller: _priceController,
                    label: 'اختيار السعر (ج.م)',
                    hint: 'اكتب السعر المناسب لك',
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    validator: (value) {
                      final v = double.tryParse((value ?? '').trim());
                      if (v == null || v <= 0) {
                        return 'أدخل سعراً صحيحاً';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  BiddingTextField(
                    controller: _notesController,
                    label: 'ملاحظات إضافية',
                    hint: 'اختياري',
                    requiredField: false,
                    maxLines: 2,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'سيصل طلبك للسائقين القريبين. يمكن للسائق قبول سعرك أو تعديل السعر، وبعدها تختار العرض اللي يناسبك.',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 12,
                      color: AuthTheme.textMuted,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AuthTheme.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: isLoading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.4,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'اطلب الآن',
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
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
