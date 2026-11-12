import 'package:flutter/material.dart';
import 'package:motorent/features/bidding_system/core/constants/bidding_vehicle_types.dart';
import 'package:motorent/features/bidding_system/domain/entities/bidding_trip.dart';
import 'package:motorent/widgets/auth/auth_theme.dart';
import 'package:motorent/widgets/storage_network_avatar.dart';
import 'package:url_launcher/url_launcher.dart';

class ActiveTripPage extends StatelessWidget {
  final BiddingTrip trip;

  const ActiveTripPage({super.key, required this.trip});

  Future<void> _callDriver(BuildContext context, String? phone) async {
    final cleaned = (phone ?? '').trim();
    if (cleaned.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('رقم السائق غير متاح')),
      );
      return;
    }

    final uri = Uri(scheme: 'tel', path: cleaned);
    if (!await canLaunchUrl(uri)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذر فتح تطبيق الاتصال')),
        );
      }
      return;
    }
    await launchUrl(uri);
  }

  Future<void> _messageDriver(BuildContext context, String? phone) async {
    final cleaned = (phone ?? '').replaceAll(RegExp(r'[^\d+]'), '');
    if (cleaned.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('رقم السائق غير متاح للمراسلة')),
      );
      return;
    }

    final smsUri = Uri(scheme: 'sms', path: cleaned);
    if (await canLaunchUrl(smsUri)) {
      await launchUrl(smsUri);
      return;
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذر فتح تطبيق الرسائل')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final offer = trip.acceptedOffer;
    final driverName = offer?.driverName ?? 'السائق';
    final driverImage = offer?.driverImage;
    final driverPhone = offer?.driverPhone;
    final price = trip.finalPrice ?? offer?.proposedPrice;
    final initial =
        driverName.isNotEmpty ? driverName.characters.first : 'س';

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'الرحلة قيد التنفيذ',
          style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
      ),
      body: Container(
        decoration: AuthTheme.screenBackground(),
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AuthTheme.fieldBorder),
              ),
              child: Column(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0C9F6A).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'جاري التنفيذ',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0C9F6A),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  StorageNetworkAvatar(
                    imagePath: driverImage,
                    initial: initial,
                    size: 84,
                    backgroundColor: AuthTheme.primary.withValues(alpha: 0.15),
                    textColor: AuthTheme.primaryDark,
                    fontSize: 32,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    driverName,
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AuthTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    BiddingVehicleTypes.labelOf(trip.vehicleType),
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      color: AuthTheme.textMuted,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    price == null
                        ? '—'
                        : '${price.toStringAsFixed(0)} ج.م',
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: AuthTheme.primaryDark,
                    ),
                  ),
                  const Text(
                    'السعر المتفق عليه',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      color: AuthTheme.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AuthTheme.fieldBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _infoRow(Icons.my_location, 'من', trip.pickupAddress),
                  const SizedBox(height: 10),
                  _infoRow(Icons.flag_outlined, 'إلى', trip.dropoffAddress),
                  if (trip.description.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    _infoRow(Icons.notes_outlined, 'الوصف', trip.description),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 22),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: () => _callDriver(context, driverPhone),
                      icon: const Icon(Icons.call),
                      label: const Text(
                        'اتصال',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0C9F6A),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 52,
                    child: OutlinedButton.icon(
                      onPressed: () => _messageDriver(context, driverPhone),
                      icon: const Icon(Icons.chat_bubble_outline),
                      label: const Text(
                        'رسالة',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AuthTheme.primaryDark,
                        side: const BorderSide(color: AuthTheme.primary),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AuthTheme.primary),
        const SizedBox(width: 8),
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
                  style: const TextStyle(fontWeight: FontWeight.w700),
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
