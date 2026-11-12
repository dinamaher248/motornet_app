import 'package:flutter/material.dart';
import 'package:motorent/data/remote/url_api.dart';
import 'package:motorent/features/services/domain/entities/service_entities.dart';
import 'package:motorent/widgets/auth/auth_theme.dart';
import 'package:motorent/widgets/rating_stars.dart';

/// بطاقة متجر/مكان في قائمة «قريب منك».
class NearbyStoreCard extends StatelessWidget {
  final Store store;
  final VoidCallback onTap;

  const NearbyStoreCard({
    super.key,
    required this.store,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final imageUrl = resolveStorageImageUrl(store.image);
    final open = store.isOpen;
    final distance = (store.distanceLabel ?? '').trim();

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFECECEC)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x08000000),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: imageUrl.isNotEmpty
                    ? Image.network(
                        imageUrl,
                        width: 84,
                        height: 84,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _placeholder(),
                      )
                    : _placeholder(),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      store.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: AuthTheme.textDark,
                      ),
                    ),
                    const SizedBox(height: 6),
                    RatingStars(
                      rating: store.avgRating,
                      count: store.ratingsCount,
                      compact: true,
                      size: 16,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 15,
                          color: AuthTheme.textMuted,
                        ),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            distance.isEmpty ? 'المسافة غير محددة' : distance,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 12,
                              color: AuthTheme.textMuted,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      store.statusLabel,
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: open ? const Color(0xFF0C9F6A) : Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Container(
                width: 28,
                height: 28,
                decoration: const BoxDecoration(
                  color: Color(0xFFF3F4F6),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.chevron_left,
                  size: 20,
                  color: AuthTheme.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      width: 84,
      height: 84,
      color: AuthTheme.primary.withValues(alpha: 0.08),
      child: const Icon(Icons.storefront, color: AuthTheme.primary, size: 32),
    );
  }
}
