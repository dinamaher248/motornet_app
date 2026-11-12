import 'package:flutter/material.dart';
import 'package:motorent/models/trip_request_models.dart';
import 'package:motorent/pages/customer/trip_offers_page.dart';
import 'package:motorent/pages/order_tracking/active_order_tracking_page.dart';
import 'package:motorent/services/trip_request_service.dart';
import 'package:motorent/widgets/auth/auth_shell.dart';
import 'package:motorent/widgets/auth/auth_theme.dart';
import 'package:motorent/widgets/rating_stars.dart';
import 'package:motorent/widgets/storage_network_avatar.dart';

class TripRequestDetailPage extends StatefulWidget {
  final TripRequestItem trip;

  const TripRequestDetailPage({super.key, required this.trip});

  @override
  State<TripRequestDetailPage> createState() => _TripRequestDetailPageState();
}

class _TripRequestDetailPageState extends State<TripRequestDetailPage> {
  final _service = TripRequestService();
  late TripRequestItem _trip;
  bool _isCancelling = false;

  @override
  void initState() {
    super.initState();
    _trip = widget.trip;
    _refresh();
  }

  Future<void> _refresh() async {
    try {
      final fresh = await _service.fetchTripDetail(_trip.id);
      if (!mounted) return;
      setState(() => _trip = fresh);
    } catch (_) {}
  }

  Future<void> _cancelTrip() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إلغاء الطلب'),
        content: const Text('هل أنت متأكد من إلغاء هذا الطلب؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('لا'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('نعم، إلغاء'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isCancelling = true);
    try {
      final updated = await _service.cancelTrip(_trip.id);
      if (!mounted) return;
      setState(() {
        _trip = updated;
        _isCancelling = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم إلغاء الطلب')),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isCancelling = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final driver = _trip.acceptedDriver;

    return Scaffold(
      appBar: AppBar(
        title: const Text('تفاصيل الطلب'),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _statusBanner(),
            const SizedBox(height: 16),
            _infoCard(
              title: 'بيانات الطلب',
              children: [
                _row('نوع الخدمة', _trip.serviceTypeLabel),
                _row('نوع المركبة', _trip.vehicleTypeLabel),
                _row('مكان الاستلام', _trip.pickLoc),
                _row('مكان التوصيل', _trip.targetLoc),
                if (_trip.distanceKm != null)
                  _row('المسافة التقريبية', '${_trip.distanceKm} كم'),
                _row('الوصف', _trip.description),
                if ((_trip.notes ?? '').isNotEmpty) _row('ملاحظات', _trip.notes!),
                if (_trip.createdAt != null) _row('تاريخ الطلب', _trip.createdAt!),
              ],
            ),
            if (_trip.status == 'awaiting_offers') ...[
              const SizedBox(height: 14),
              AuthPrimaryButton(
                label: 'عرض عروض السائقين (${_trip.offersCount})',
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TripOffersPage(trip: _trip),
                    ),
                  );
                  _refresh();
                },
              ),
            ],
            if (_trip.status == 'in_progress' ||
                _trip.status == 'handed_to_driver') ...[
              const SizedBox(height: 14),
              if (driver != null)
                _infoCard(
                  title: 'السائق',
                  children: [
                    Row(
                      children: [
                        StorageNetworkAvatar(
                          imagePath: driver.image,
                          initial: (driver.name ?? 'س').characters.first,
                          size: 56,
                          backgroundColor:
                              AuthTheme.primary.withValues(alpha: 0.12),
                          textColor: AuthTheme.primary,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                driver.name ?? 'سائق',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              RatingStars(rating: driver.rating),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              const SizedBox(height: 12),
              AuthPrimaryButton(
                label: 'متابعة التنفيذ على الخريطة',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ActiveOrderTrackingPage(
                        type: 'trip_request',
                        id: _trip.id,
                      ),
                    ),
                  );
                },
              ),
            ],
            if (_trip.status == 'completed' && driver != null) ...[
              const SizedBox(height: 14),
              AuthPrimaryButton(
                label: 'تقييم السائق',
                onPressed: () => showRateSheet(
                  context,
                  title: 'قيّم السائق',
                  contextType: 'trip_request',
                  contextId: _trip.id,
                  rateeUserId: driver.id,
                ),
              ),
            ],
            if (_trip.canCancel) ...[
              const SizedBox(height: 24),
              AuthPrimaryButton(
                label: 'إلغاء الطلب',
                isLoading: _isCancelling,
                onPressed: _cancelTrip,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _statusBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AuthTheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        'الحالة: ${_trip.statusLabel}',
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontFamily: 'Cairo',
          fontWeight: FontWeight.w800,
          fontSize: 16,
        ),
      ),
    );
  }

  Widget _infoCard({
    required String title,
    required List<Widget> children,
  }) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AuthTheme.textMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(fontSize: 14, height: 1.4),
          ),
        ],
      ),
    );
  }
}
