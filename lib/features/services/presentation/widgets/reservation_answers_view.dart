import 'package:flutter/material.dart';
import 'package:motorent/data/remote/url_api.dart';
import 'package:motorent/features/services/domain/entities/reservation_entities.dart';
import 'package:motorent/widgets/auth/auth_theme.dart';

/// يعرض إجابات العميل على حقول النموذج (نص + صور) — يستخدمه العميل والتاجر.
class ReservationAnswersView extends StatelessWidget {
  final List<ReservationAnswer> answers;

  const ReservationAnswersView({super.key, required this.answers});

  @override
  Widget build(BuildContext context) {
    if (answers.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final a in answers)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: a.isImage ? _imageRow(context, a) : _textRow(a),
          ),
      ],
    );
  }

  Widget _textRow(ReservationAnswer a) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (a.label.isNotEmpty)
          Text(
            '${a.label}: ',
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontWeight: FontWeight.w700,
              fontSize: 13,
              color: AuthTheme.textMuted,
            ),
          ),
        Expanded(
          child: Text(
            a.value,
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

  Widget _imageRow(BuildContext context, ReservationAnswer a) {
    final url = resolveStorageImageUrl(a.value);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (a.label.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              a.label,
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: AuthTheme.textMuted,
              ),
            ),
          ),
        if (url.isEmpty)
          const Text('—')
        else
          GestureDetector(
            onTap: () => showDialog<void>(
              context: context,
              builder: (_) => Dialog(
                child: InteractiveViewer(
                  child: Image.network(
                    url,
                    errorBuilder: (_, __, ___) => const Padding(
                      padding: EdgeInsets.all(24),
                      child: Icon(Icons.broken_image_outlined),
                    ),
                  ),
                ),
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                url,
                width: 110,
                height: 110,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 110,
                  height: 110,
                  color: AuthTheme.primary.withValues(alpha: 0.08),
                  child: const Icon(Icons.broken_image_outlined),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
