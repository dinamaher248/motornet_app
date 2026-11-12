import 'dart:async';

import 'package:flutter/material.dart';
import 'package:motorent/models/trip_request_models.dart';
import 'package:motorent/pages/order_tracking/active_order_tracking_page.dart';
import 'package:motorent/services/trip_request_service.dart';
import 'package:motorent/widgets/auth/auth_theme.dart';
import 'package:motorent/widgets/rating_stars.dart';
import 'package:motorent/widgets/storage_network_avatar.dart';

class TripOffersPage extends StatefulWidget {
  final TripRequestItem trip;

  const TripOffersPage({super.key, required this.trip});

  @override
  State<TripOffersPage> createState() => _TripOffersPageState();
}

class _TripOffersPageState extends State<TripOffersPage> {
  final _service = TripRequestService();
  late TripRequestItem _trip;
  List<TripOfferItem> _offers = [];
  bool _isLoading = true;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _trip = widget.trip;
    _loadOffers();
    _pollTimer = Timer.periodic(const Duration(seconds: 8), (_) => _loadOffers(silent: true));
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadOffers({bool silent = false}) async {
    if (!silent) setState(() => _isLoading = true);
    try {
      final offers = await _service.fetchOffers(_trip.id);
      if (!mounted) return;
      setState(() {
        _offers = offers.where((o) => o.status == 'pending').toList();
        _isLoading = false;
      });
    } catch (_) {
      if (!silent && mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _acceptOffer(TripOfferItem offer) async {
    try {
      await _service.acceptOffer(tripId: _trip.id, offerId: offer.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم قبول العرض وبدء تنفيذ الطلب')),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ActiveOrderTrackingPage(
            type: 'trip_request',
            id: _trip.id,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('عروض السائقين'),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: _loadOffers,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _buildTripSummary(),
            const SizedBox(height: 20),
            const Text(
              'اختر أفضل عرض يناسبك',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_offers.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  'بانتظار عروض السائقين... سيتم تحديث القائمة تلقائيًا',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AuthTheme.textMuted),
                ),
              )
            else
              ..._offers.map(_buildOfferCard),
          ],
        ),
      ),
    );
  }

  Widget _buildTripSummary() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('من: ${_trip.pickLoc}'),
            const SizedBox(height: 6),
            Text('إلى: ${_trip.targetLoc}'),
            if (_trip.distanceKm != null) ...[
              const SizedBox(height: 6),
              Text('المسافة التقريبية: ${_trip.distanceKm} كم'),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildOfferCard(TripOfferItem offer) {
    final driver = offer.driver;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                StorageNetworkAvatar(
                  imagePath: driver.image,
                  initial: (driver.name ?? 'س').characters.first,
                  size: 54,
                  backgroundColor: AuthTheme.primary.withOpacity(0.12),
                  textColor: AuthTheme.primary,
                  fontSize: 22,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        driver.name ?? 'سائق',
                        style: const TextStyle(
                          fontFamily: 'Cairo',
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      RatingStars(rating: driver.rating),
                      if (driver.vehicleTypeLabel != null) ...[
                        const SizedBox(height: 4),
                        Text(driver.vehicleTypeLabel!),
                      ],
                    ],
                  ),
                ),
                Text(
                  '${offer.amount.toStringAsFixed(0)} ج.م',
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.w800,
                    color: AuthTheme.primary,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _acceptOffer(offer),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AuthTheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('قبول'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
