import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:motorent/data/local/cache_helper.dart';
import 'package:motorent/data/remote/url_api.dart';
import 'package:motorent/widgets/auth/auth_theme.dart';

class RatingStars extends StatelessWidget {
  final double rating;
  final int? count;
  final double size;
  final bool compact;

  const RatingStars({
    super.key,
    required this.rating,
    this.count,
    this.size = 16,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final value = rating <= 0 ? 0.0 : rating;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.star_rounded, size: size, color: const Color(0xFFF59E0B)),
        const SizedBox(width: 4),
        Text(
          value <= 0 ? 'جديد' : value.toStringAsFixed(1),
          style: TextStyle(
            fontFamily: 'Cairo',
            fontWeight: FontWeight.w700,
            fontSize: compact ? 12 : 13,
            color: AuthTheme.textMuted,
          ),
        ),
        if (count != null && count! > 0) ...[
          const SizedBox(width: 4),
          Text(
            '($count)',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: compact ? 11 : 12,
              color: AuthTheme.textMuted,
            ),
          ),
        ],
      ],
    );
  }
}

Future<bool> submitRating({
  required double score,
  required String contextType,
  required int contextId,
  int? rateeUserId,
  int? rateeMerchantId,
  String? comment,
}) async {
  final token = CacheHelper.getData(key: 'token');
  if (token == null) return false;

  final response = await Dio().post(
    ratingsEP,
    data: {
      'score': score.round().clamp(1, 5),
      'context_type': contextType,
      'context_id': contextId,
      if (rateeUserId != null) 'ratee_user_id': rateeUserId,
      if (rateeMerchantId != null) 'ratee_merchant_id': rateeMerchantId,
      if (comment != null && comment.trim().isNotEmpty) 'comment': comment.trim(),
    },
    options: Options(
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
      validateStatus: (s) => s != null && s < 600,
    ),
  );

  return response.statusCode == 200 || response.statusCode == 201;
}

Future<void> showRateSheet(
  BuildContext context, {
  required String title,
  required String contextType,
  required int contextId,
  int? rateeUserId,
  int? rateeMerchantId,
}) async {
  int selected = 5;
  final commentCtrl = TextEditingController();

  final ok = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) {
      return Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 18,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
        ),
        child: StatefulBuilder(
          builder: (context, setModal) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (i) {
                    final star = i + 1;
                    return IconButton(
                      onPressed: () => setModal(() => selected = star),
                      icon: Icon(
                        star <= selected
                            ? Icons.star_rounded
                            : Icons.star_outline_rounded,
                        color: const Color(0xFFF59E0B),
                        size: 34,
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: commentCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: 'تعليق اختياري',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AuthTheme.primary,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text(
                      'إرسال التقييم',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      );
    },
  );

  if (ok != true || !context.mounted) return;

  try {
    final success = await submitRating(
      score: selected.toDouble(),
      contextType: contextType,
      contextId: contextId,
      rateeUserId: rateeUserId,
      rateeMerchantId: rateeMerchantId,
      comment: commentCtrl.text,
    );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? 'تم حفظ التقييم' : 'تعذر حفظ التقييم'),
      ),
    );
  } catch (e) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
    );
  } finally {
    commentCtrl.dispose();
  }
}
