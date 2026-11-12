import 'package:flutter/material.dart';
import 'package:motorent/features/driver_interface/domain/entities/driver_entities.dart';
import 'package:motorent/pages/order_tracking/active_order_tracking_page.dart';
import 'package:motorent/widgets/auth/auth_theme.dart';
import 'package:motorent/widgets/rating_stars.dart';

class DriverTripCard extends StatelessWidget {
  final DriverTrip trip;
  final VoidCallback? onTap;
  final bool offerLoading;
  final bool hasActiveTrip;

  const DriverTripCard({
    super.key,
    required this.trip,
    this.onTap,
    this.offerLoading = false,
    this.hasActiveTrip = false,
  });

  void _openTracking(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ActiveOrderTrackingPage(
          type: trip.type,
          id: trip.id,
          isDriverView: true,
        ),
      ),
    );
  }

  bool get _isActive {
    final s = (trip.status ?? '').toLowerCase().trim();
    return trip.showContact ||
        s == 'in_progress' ||
        s == 'going_to_pickup' ||
        s == 'picked_up' ||
        s == 'driver_assigned';
  }

  bool get _isCompleted {
    final s = (trip.status ?? '').toLowerCase().trim();
    return s == 'completed' || (trip.completedAt ?? '').isNotEmpty;
  }

  Color get _statusColor {
    if (_isCompleted) return const Color(0xFF0C9F6A);
    if ((trip.status ?? '') == 'picked_up') return const Color(0xFF1E88E5);
    if ((trip.status ?? '') == 'going_to_pickup') return AuthTheme.primary;
    return const Color(0xFFE6910A);
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap ?? (_isActive ? () => _openTracking(context) : null),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AuthTheme.fieldBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      trip.title,
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      _isCompleted
                          ? 'مكتمل'
                          : _isActive
                              ? 'جاري'
                              : (trip.status ?? ''),
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: _statusColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _row(Icons.trip_origin, 'الاستلام', trip.pickup ?? '-'),
              const SizedBox(height: 6),
              _row(Icons.flag_outlined, 'التوصيل', trip.dropoff ?? '-'),
              if ((trip.description ?? '').trim().isNotEmpty) ...[
                const SizedBox(height: 6),
                _row(Icons.notes, 'الوصف', trip.description!),
              ],
              if ((trip.customerPrice ?? trip.amount) != null) ...[
                const SizedBox(height: 6),
                _row(
                  Icons.payments_outlined,
                  trip.myOfferAmount != null ? 'عرضك' : 'سعر العميل',
                  '${(trip.myOfferAmount ?? trip.customerPrice ?? trip.amount)!.toStringAsFixed(0)} ج.م',
                ),
              ],
              if ((trip.customerName ?? '').isNotEmpty ||
                  (trip.customerRating ?? 0) > 0) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.person_outline,
                        size: 16, color: AuthTheme.textMuted),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        trip.customerName ?? 'عميل',
                        style: const TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 13,
                          color: AuthTheme.textDark,
                        ),
                      ),
                    ),
                    RatingStars(
                      rating: trip.customerRating ?? 0,
                      count: trip.customerRatingsCount,
                      size: 15,
                      compact: true,
                    ),
                  ],
                ),
              ],
              if (_isActive) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0C9F6A).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'جاري التنفيذ — اضغط لإكمال التسليم',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontWeight: FontWeight.w800,
                          color: Colors.green.shade700,
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => _openTracking(context),
                          icon: const Icon(Icons.map_outlined),
                          label: const Text(
                            'متابعة / تم التسليم',
                            style: TextStyle(fontFamily: 'Cairo'),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AuthTheme.primary,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ] else if (trip.canOffer) ...[
                const SizedBox(height: 10),
                Text(
                  'اضغط لعرض المسافة وتقديم عرض سعر',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AuthTheme.primary.withValues(alpha: 0.9),
                  ),
                ),
              ] else if (hasActiveTrip) ...[
                const SizedBox(height: 10),
                Text(
                  'لا يمكن قبول طلب جديد أثناء تنفيذ طلب حالي',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.orange.shade800,
                  ),
                ),
              ] else if (_isCompleted) ...[
                const SizedBox(height: 8),
                Text(
                  'تم إنجاز الطلب',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.green.shade700,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AuthTheme.textMuted),
        const SizedBox(width: 6),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 13,
                color: AuthTheme.textDark,
              ),
              children: [
                TextSpan(
                  text: '$label: ',
                  style: const TextStyle(
                    color: AuthTheme.textMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextSpan(text: value),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
