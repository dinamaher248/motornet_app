import 'dart:async';

import 'package:flutter/material.dart';
import 'package:motorent/features/bidding_system/bidding_injection.dart';
import 'package:motorent/features/bidding_system/domain/entities/bidding_trip.dart';
import 'package:motorent/features/bidding_system/presentation/pages/trip_details_screen.dart';
import 'package:motorent/models/home_response.dart';
import 'package:motorent/pages/order_tracking/active_order_tracking_page.dart';
import 'package:motorent/pages/services/customer_service_order_detail_page.dart';
import 'package:motorent/providers/home_provider.dart';
import 'package:motorent/services/local_service_api.dart';
import 'package:motorent/services/notification_store.dart';
import 'package:motorent/utils/notification_kind.dart';
import 'package:motorent/widgets/auth/auth_theme.dart';
import 'package:provider/provider.dart';

/// طلبات العميل غير المكتملة على الصفحة الرئيسية.
class CustomerActiveOrdersSection extends StatefulWidget {
  const CustomerActiveOrdersSection({super.key});

  @override
  State<CustomerActiveOrdersSection> createState() =>
      _CustomerActiveOrdersSectionState();
}

class _CustomerActiveOrdersSectionState
    extends State<CustomerActiveOrdersSection> with WidgetsBindingObserver {
  List<HomeOrder> _orders = const [];
  bool _loading = true;
  Timer? _poll;
  StreamSubscription<void>? _notifSub;
  bool _fetching = false;

  static const _doneStatuses = {
    'completed',
    'cancelled',
    'rejected',
    'canceled',
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
    _poll = Timer.periodic(const Duration(seconds: 10), (_) => _refresh());
    _notifSub = NotificationStore.instance.changes.listen((_) async {
      try {
        final items = await NotificationStore.instance.getAll();
        if (items.isEmpty || items.first.isRead) return;
        final action = NotificationKind.normalize(items.first.action);
        const tripActions = {
          NotificationKind.newTrip,
          NotificationKind.biddingTrip,
          NotificationKind.offerAccepted,
          NotificationKind.tripAccepted,
          NotificationKind.tripOffer,
          NotificationKind.tripCancelled,
          NotificationKind.serviceOrderStatus,
          NotificationKind.serviceDriverAssigned,
        };
        if (tripActions.contains(action)) {
          await _refresh();
        }
      } catch (_) {}
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refresh();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _poll?.cancel();
    _notifSub?.cancel();
    super.dispose();
  }

  bool _isActive(HomeOrder o) {
    final status = (o.status ?? '').toLowerCase().trim();
    if (_doneStatuses.contains(status)) return false;
    return o.isActive;
  }

  HomeOrder _fromBiddingTrip(BiddingTrip trip) {
    final driver = trip.resolvedDriver;
    return HomeOrder(
      id: trip.id,
      type: 'bidding_trip',
      title: 'مشوار / توصيل',
      amount: trip.finalPrice,
      msg: trip.description.isNotEmpty ? trip.description : trip.notes,
      pickLoc: trip.pickupAddress,
      targetLoc: trip.dropoffAddress,
      status: trip.status,
      statusLabel: trip.statusLabelAr,
      isActive: !trip.isCompleted && !trip.isCancelled,
      createdAt: trip.createdAt?.toIso8601String(),
      driver: driver == null
          ? null
          : HomeOrderDriver(
              id: driver.id,
              name: driver.name,
              phone: driver.phone,
            ),
    );
  }

  String _key(HomeOrder o) => '${o.type ?? 'bidding_trip'}:${o.id}';

  Future<void> _refresh() async {
    if (!mounted || _fetching) return;
    _fetching = true;

    final merged = <String, HomeOrder>{};

    // 1) حدّث /home بهدوء ثم اقرأ الطلبات الجارية
    try {
      final provider = Provider.of<HomeProvider>(context, listen: false);
      await provider.refreshHomeSilent();
      for (final o in provider.homeData?.data?.orders ?? const <HomeOrder>[]) {
        if (_isActive(o) && o.id != null) merged[_key(o)] = o;
      }
    } catch (_) {}

    // 2) مشاوير المزايدة غير المكتملة (مصدر موثوق إضافي)
    try {
      final result = await BiddingInjection.createRepository().getMyTrips();
      result.fold((_) {}, (trips) {
        for (final trip in trips) {
          if (trip.isCompleted || trip.isCancelled) continue;
          final order = _fromBiddingTrip(trip);
          if (order.id != null) merged[_key(order)] = order;
        }
      });
    } catch (_) {}

    if (!mounted) {
      _fetching = false;
      return;
    }

    final list = merged.values.toList()
      ..sort((a, b) => (b.createdAt ?? '').compareTo(a.createdAt ?? ''));

    setState(() {
      _orders = list;
      _loading = false;
    });
    _fetching = false;
  }

  Future<void> _openOrder(HomeOrder order) async {
    final id = order.id;
    if (id == null) return;

    final type = order.type ?? 'bidding_trip';

    if (order.isPendingBidding) {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => TripDetailsScreen(tripId: id)),
      );
    } else if (type == 'ride_book') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('افتح الطلب من سجل الحجوزات')),
      );
      return;
    } else if (type == 'service_order' || type == 'custom_order') {
      await _openServiceOrder(type, id, order.status);
    } else {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ActiveOrderTrackingPage(
            type: type,
            id: id,
            isDriverView: false,
          ),
        ),
      );
    }

    if (mounted) await _refresh();
  }

  Future<void> _openServiceOrder(String type, int id, String? status) async {
    final trackingStatuses = {
      'driver_assigned',
      'in_progress',
      'handed_to_driver',
      'on_the_way',
      'picked_up',
    };
    final statusKey = (status ?? '').toLowerCase().trim();

    if (trackingStatuses.contains(statusKey)) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ActiveOrderTrackingPage(
            type: type,
            id: id,
            isDriverView: false,
          ),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final item = await LocalServiceApi().fetchOrder(id);
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CustomerServiceOrderDetailPage(order: item),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ActiveOrderTrackingPage(
            type: type,
            id: id,
            isDriverView: false,
          ),
        ),
      );
    }
  }

  Color _statusColor(String? status) {
    switch (status) {
      case 'pending':
      case 'awaiting_offers':
      case 'new':
      case 'pending_vendor':
      case 'priced':
        return const Color(0xFFE6910A);
      case 'in_progress':
      case 'handed_to_driver':
      case 'driver_assigned':
      case 'preparing':
      case 'accepted':
        return const Color(0xFF0C9F6A);
      default:
        return AuthTheme.textMuted;
    }
  }

  @override
  Widget build(BuildContext context) {
    // أعد البناء عند تحديث HomeProvider
    try {
      context.watch<HomeProvider>();
    } catch (_) {}

    final orders = _orders;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Icon(Icons.receipt_long_outlined,
                size: 20, color: AuthTheme.primary),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'طلباتك الجارية',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  color: AuthTheme.textDark,
                ),
              ),
            ),
            if (_loading)
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else if (orders.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AuthTheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${orders.length}',
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.w800,
                    color: AuthTheme.primary,
                    fontSize: 12,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),
        if (!_loading && orders.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 22,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AuthTheme.fieldBorder),
            ),
            child: const Text(
              'لا توجد طلبات جارية حالياً.\nاطلب مشوار أو توصيل من الأزرار بالأعلى.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Cairo',
                color: AuthTheme.textMuted,
                height: 1.5,
              ),
            ),
          )
        else if (orders.isNotEmpty)
          ...orders.map(
            (order) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _ActiveOrderCard(
                order: order,
                statusColor: _statusColor(order.status),
                onTap: () => _openOrder(order),
              ),
            ),
          ),
      ],
    );
  }
}

class _ActiveOrderCard extends StatelessWidget {
  final HomeOrder order;
  final Color statusColor;
  final VoidCallback onTap;

  const _ActiveOrderCard({
    required this.order,
    required this.statusColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final statusText = (order.statusLabel ?? order.status ?? 'جاري').trim();
    final title = (order.title ?? 'طلب').trim();
    final pickup = (order.pickLoc ?? '').trim();
    final dropoff = (order.targetLoc ?? '').trim();
    final driverName = order.driver?.name;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: statusColor.withValues(alpha: 0.35),
              width: 1.4,
            ),
            boxShadow: const [
              BoxShadow(
                color: AuthTheme.cardShadow,
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        color: AuthTheme.textDark,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      statusText,
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),
              if (pickup.isNotEmpty) ...[
                const SizedBox(height: 10),
                _line(Icons.trip_origin, 'من', pickup),
              ],
              if (dropoff.isNotEmpty) ...[
                const SizedBox(height: 6),
                _line(Icons.flag_outlined, 'إلى', dropoff),
              ],
              if ((order.msg ?? '').trim().isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  order.msg!.trim(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 12,
                    color: AuthTheme.textMuted,
                  ),
                ),
              ],
              const SizedBox(height: 10),
              Row(
                children: [
                  if (driverName != null && driverName.isNotEmpty)
                    Expanded(
                      child: Text(
                        'السائق: $driverName',
                        style: const TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AuthTheme.textDark,
                        ),
                      ),
                    )
                  else
                    const Spacer(),
                  Text(
                    order.isPendingBidding ? 'عرض العروض' : 'متابعة الطلب',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                      color: statusColor,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.arrow_back_ios_new, size: 12, color: statusColor),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _line(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AuthTheme.primary),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            '$label: $value',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontSize: 13,
              color: AuthTheme.textDark,
            ),
          ),
        ),
      ],
    );
  }
}
