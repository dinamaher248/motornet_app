import 'package:flutter/material.dart';
import 'package:motorent/features/bidding_system/domain/entities/bidding_offer.dart';
import 'package:motorent/widgets/auth/auth_theme.dart';
import 'package:motorent/widgets/storage_network_avatar.dart';

class OfferCard extends StatelessWidget {
  final BiddingOffer offer;
  final bool isAccepting;
  final VoidCallback onAccept;
  final double? customerPrice;

  const OfferCard({
    super.key,
    required this.offer,
    required this.onAccept,
    this.isAccepting = false,
    this.customerPrice,
  });

  @override
  Widget build(BuildContext context) {
    final initial =
        offer.driverName.isNotEmpty ? offer.driverName.characters.first : 'س';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
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
      child: Row(
        children: [
          StorageNetworkAvatar(
            imagePath: offer.driverImage,
            initial: initial,
            size: 54,
            backgroundColor: AuthTheme.primary.withValues(alpha: 0.15),
            textColor: AuthTheme.primaryDark,
            fontSize: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  offer.driverName,
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: AuthTheme.textDark,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.star_rounded,
                        size: 18, color: Color(0xFFF59E0B)),
                    const SizedBox(width: 4),
                    Text(
                      offer.rating.toStringAsFixed(1),
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.w600,
                        color: AuthTheme.textMuted,
                      ),
                    ),
                  ],
                ),
                if ((offer.distanceLabel ?? '').trim().isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.near_me_outlined,
                          size: 16, color: AuthTheme.textMuted),
                      const SizedBox(width: 4),
                      Text(
                        'يبعد ${offer.distanceLabel}',
                        style: const TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 12,
                          color: AuthTheme.textMuted,
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 6),
                Text(
                  '${offer.proposedPrice.toStringAsFixed(0)} ج.م',
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: AuthTheme.primaryDark,
                  ),
                ),
                if (customerPrice != null && customerPrice! > 0) ...[
                  const SizedBox(height: 2),
                  Text(
                    (offer.proposedPrice - customerPrice!).abs() < 0.01
                        ? 'موافق على سعرك'
                        : offer.proposedPrice < customerPrice!
                            ? 'أقل من سعرك'
                            : 'أعلى من سعرك',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: (offer.proposedPrice - customerPrice!).abs() < 0.01
                          ? const Color(0xFF0C9F6A)
                          : AuthTheme.textMuted,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            height: 42,
            child: ElevatedButton(
              onPressed: isAccepting ? null : onAccept,
              style: ElevatedButton.styleFrom(
                backgroundColor: AuthTheme.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: isAccepting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'قبول',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
