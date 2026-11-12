import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:motorent/features/bidding_system/core/constants/bidding_vehicle_types.dart';
import 'package:motorent/features/bidding_system/domain/entities/bidding_trip.dart';
import 'package:motorent/widgets/auth/auth_theme.dart';

class TripTrackingCard extends StatelessWidget {
  final BiddingTrip trip;
  final VoidCallback onTap;

  const TripTrackingCard({
    super.key,
    required this.trip,
    required this.onTap,
  });

  Color get _statusColor {
    switch (trip.status) {
      case 'pending':
      case 'awaiting_offers':
        return Colors.orange;
      case 'in_progress':
      case 'handed_to_driver':
        return const Color(0xFF0C9F6A);
      case 'completed':
        return Colors.blue;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '—';
    return DateFormat('yyyy/MM/dd - HH:mm').format(date.toLocal());
  }

  @override
  Widget build(BuildContext context) {
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
            border: Border.all(color: AuthTheme.fieldBorder),
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
                      BiddingVehicleTypes.labelOf(trip.vehicleType),
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
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
                      color: _statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      trip.statusLabelAr,
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        color: _statusColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _line(Icons.my_location, 'من', trip.shortPickup),
              const SizedBox(height: 6),
              _line(Icons.flag_outlined, 'إلى', trip.shortDropoff),
              const SizedBox(height: 8),
              Text(
                _formatDate(trip.createdAt),
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 12,
                  color: AuthTheme.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _line(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AuthTheme.primary),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            '$label: $value',
            maxLines: 1,
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
