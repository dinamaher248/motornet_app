import 'package:flutter/material.dart';
import 'package:motorent/features/driver_interface/domain/entities/driver_entities.dart';
import 'package:motorent/features/driver_interface/driver_interface_injection.dart';
import 'package:motorent/features/driver_interface/presentation/widgets/driver_shimmer.dart';
import 'package:motorent/features/driver_interface/presentation/widgets/driver_trip_card.dart';
import 'package:motorent/pages/order_tracking/active_order_tracking_page.dart';
import 'package:motorent/widgets/auth/auth_theme.dart';

class DriverMyTripsScreen extends StatefulWidget {
  const DriverMyTripsScreen({super.key});

  @override
  State<DriverMyTripsScreen> createState() => _DriverMyTripsScreenState();
}

class _DriverMyTripsScreenState extends State<DriverMyTripsScreen> {
  List<DriverTrip> _trips = [];
  bool _loading = true;
  String? _error;
  String _filter = 'all'; // all | active | completed

  static const _activeStatuses = {
    'in_progress',
    'going_to_pickup',
    'picked_up',
    'driver_assigned',
    'handed_to_driver',
    'in_delivery',
  };

  bool _isActive(DriverTrip trip) {
    final s = (trip.status ?? '').toLowerCase().trim();
    if (_activeStatuses.contains(s)) return true;
    return trip.showContact && s != 'completed';
  }

  bool _isCompleted(DriverTrip trip) {
    final s = (trip.status ?? '').toLowerCase().trim();
    return s == 'completed' || trip.completedAt != null;
  }

  List<DriverTrip> get _filtered {
    switch (_filter) {
      case 'active':
        return _trips.where(_isActive).toList();
      case 'completed':
        return _trips.where(_isCompleted).toList();
      default:
        return _trips;
    }
  }

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
    final result = await DriverInterfaceInjection.repository.fetchMyTrips();
    if (!mounted) return;
    result.fold(
      (failure) => setState(() {
        _loading = false;
        _error = failure.message;
      }),
      (trips) => setState(() {
        _loading = false;
        _trips = trips;
      }),
    );
  }

  Future<void> _openTrip(DriverTrip trip) async {
    // الطلبات النشطة → شاشة المتابعة/التسليم مباشرة
    if (_isActive(trip)) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ActiveOrderTrackingPage(
            type: trip.type,
            id: trip.id,
            isDriverView: true,
          ),
        ),
      );
      if (mounted) await _load();
      return;
    }

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _displayTitle(trip),
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontWeight: FontWeight.w800,
                fontSize: 17,
              ),
            ),
            const SizedBox(height: 12),
            DriverTripCard(trip: trip),
          ],
        ),
      ),
    );
  }

  String _displayTitle(DriverTrip trip) {
    final s = (trip.status ?? '').toLowerCase().trim();
    switch (s) {
      case 'completed':
        return 'طلب مكتمل';
      case 'going_to_pickup':
        return 'في الطريق إلى الاستلام';
      case 'picked_up':
        return 'جارٍ التوصيل';
      case 'cancelled':
      case 'rejected':
        return 'طلب ملغي';
      case 'in_progress':
      case 'driver_assigned':
        return 'طلب قيد التنفيذ';
      default:
        if (_isCompleted(trip)) return 'طلب مكتمل';
        return trip.title;
    }
  }

  @override
  Widget build(BuildContext context) {
    final list = _filtered;
    final activeCount = _trips.where(_isActive).length;
    final completedCount = _trips.where(_isCompleted).length;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(
          'طلباتي',
          style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
      ),
      body: Container(
        decoration: AuthTheme.screenBackground(),
        child: _loading
            ? const DriverListShimmer()
            : RefreshIndicator(
                onRefresh: _load,
                child: _error != null
                    ? ListView(
                        children: [
                          const SizedBox(height: 80),
                          Center(child: Text(_error!)),
                          TextButton(
                            onPressed: _load,
                            child: const Text('إعادة المحاولة'),
                          ),
                        ],
                      )
                    : Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  _chip('الكل', 'all', _trips.length),
                                  _chip('قيد التنفيذ', 'active', activeCount),
                                  _chip('مكتملة', 'completed', completedCount),
                                ],
                              ),
                            ),
                          ),
                          Expanded(
                            child: list.isEmpty
                                ? ListView(
                                    physics:
                                        const AlwaysScrollableScrollPhysics(),
                                    children: [
                                      const SizedBox(height: 120),
                                      Center(
                                        child: Text(
                                          _filter == 'completed'
                                              ? 'لا توجد طلبات مكتملة بعد'
                                              : _filter == 'active'
                                                  ? 'لا توجد طلبات قيد التنفيذ'
                                                  : 'لا توجد طلبات بعد',
                                          style: const TextStyle(
                                            fontFamily: 'Cairo',
                                            color: AuthTheme.textMuted,
                                          ),
                                        ),
                                      ),
                                    ],
                                  )
                                : ListView.separated(
                                    physics:
                                        const AlwaysScrollableScrollPhysics(),
                                    padding: const EdgeInsets.fromLTRB(
                                        16, 8, 16, 100),
                                    itemCount: list.length,
                                    separatorBuilder: (_, __) =>
                                        const SizedBox(height: 12),
                                    itemBuilder: (context, index) {
                                      final trip = list[index];
                                      return DriverTripCard(
                                        trip: trip.copyWith(
                                          title: _displayTitle(trip),
                                        ),
                                        onTap: () => _openTrip(trip),
                                      );
                                    },
                                  ),
                          ),
                        ],
                      ),
              ),
      ),
    );
  }

  Widget _chip(String label, String value, int count) {
    final selected = _filter == value;
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: ChoiceChip(
        label: Text(
          '$label ($count)',
          style: TextStyle(
            fontFamily: 'Cairo',
            fontSize: 12,
            color: selected ? Colors.white : Colors.black87,
          ),
        ),
        selected: selected,
        selectedColor: AuthTheme.primary,
        onSelected: (_) => setState(() => _filter = value),
      ),
    );
  }
}
