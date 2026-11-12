import 'package:flutter/material.dart';
import 'package:motorent/data/remote/ApiService.dart';
import 'package:motorent/features/bidding_system/presentation/pages/bidding_request_form_page.dart';
import 'package:motorent/features/bidding_system/presentation/widgets/vehicle_type_tile.dart';
import 'package:motorent/features/vendor_interface/domain/entities/vendor_order_dispatch_prefill.dart';
import 'package:motorent/models/vehicle_type_model.dart';
import 'package:motorent/widgets/auth/auth_theme.dart';

/// Loads vehicle types for a category (quick_trip / goods) from the API.
class DynamicVehicleSelectPage extends StatefulWidget {
  final String category;
  final String pageTitle;
  final String serviceTitle;
  final String descriptionLabel;
  final Color accentColor;
  final VendorOrderDispatchPrefill? vendorDispatch;

  const DynamicVehicleSelectPage({
    super.key,
    required this.category,
    required this.pageTitle,
    required this.serviceTitle,
    required this.descriptionLabel,
    this.accentColor = AuthTheme.primary,
    this.vendorDispatch,
  });

  @override
  State<DynamicVehicleSelectPage> createState() =>
      _DynamicVehicleSelectPageState();
}

class _DynamicVehicleSelectPageState extends State<DynamicVehicleSelectPage> {
  bool _loading = true;
  String? _error;
  List<VehicleTypeModel> _types = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final types = await ApiService().fetchVehicleTypes(
        category: widget.category,
      );
      if (!mounted) return;
      setState(() {
        _types = types;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'تعذر تحميل وسائل النقل. حاول مرة أخرى.';
        _loading = false;
      });
    }
  }

  void _openForm(VehicleTypeModel type) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BiddingRequestFormPage(
          vehicleType: type.key,
          title: '${widget.serviceTitle} - ${type.displayName}',
          descriptionLabel: widget.descriptionLabel,
          vendorDispatch: widget.vendorDispatch,
        ),
      ),
    );
  }

  IconData _iconFor(VehicleTypeModel type) {
    final key = type.key.toLowerCase();
    if (key.contains('scooter') || key.contains('سكوتر')) {
      return Icons.electric_scooter;
    }
    if (key.contains('motor') || key.contains('bike')) {
      return Icons.two_wheeler;
    }
    if (key.contains('tricycl') || key.contains('toktok')) {
      return Icons.electric_rickshaw_outlined;
    }
    if (key.contains('half')) {
      return Icons.fire_truck_outlined;
    }
    if (key.contains('truck') || key.contains('quarter')) {
      return Icons.local_shipping_outlined;
    }
    return Icons.directions_car_filled_outlined;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.pageTitle,
          style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
      ),
      body: Container(
        decoration: AuthTheme.screenBackground(),
        child: RefreshIndicator(
          onRefresh: _load,
          child: _loading
              ? ListView(
                  children: const [
                    SizedBox(height: 120),
                    Center(child: CircularProgressIndicator()),
                  ],
                )
              : _error != null
                  ? ListView(
                      padding: const EdgeInsets.all(24),
                      children: [
                        const SizedBox(height: 80),
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontFamily: 'Cairo',
                            color: Colors.red,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Center(
                          child: ElevatedButton(
                            onPressed: _load,
                            child: const Text('إعادة المحاولة'),
                          ),
                        ),
                      ],
                    )
                  : _types.isEmpty
                      ? ListView(
                          padding: const EdgeInsets.all(24),
                          children: const [
                            SizedBox(height: 80),
                            Text(
                              'لا توجد وسائل نقل متاحة حالياً.\nحاول مرة أخرى بعد قليل.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                color: AuthTheme.textMuted,
                              ),
                            ),
                          ],
                        )
                      : GridView.builder(
                          padding: const EdgeInsets.all(20),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 14,
                            crossAxisSpacing: 14,
                            childAspectRatio: 0.95,
                          ),
                          itemCount: _types.length,
                          itemBuilder: (context, index) {
                            final type = _types[index];
                            return VehicleTypeTile(
                              title: type.displayName,
                              icon: _iconFor(type),
                              onTap: () => _openForm(type),
                            );
                          },
                        ),
        ),
      ),
    );
  }
}
