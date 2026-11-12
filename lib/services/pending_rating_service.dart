import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:motorent/data/local/cache_helper.dart';
import 'package:motorent/data/remote/url_api.dart';
import 'package:motorent/widgets/rating_stars.dart';

class PendingRatingItem {
  final String type;
  final int id;
  final String contextType;
  final int contextId;
  final int rateeUserId;
  final String title;
  final String subtitle;

  PendingRatingItem({
    required this.type,
    required this.id,
    required this.contextType,
    required this.contextId,
    required this.rateeUserId,
    required this.title,
    required this.subtitle,
  });

  factory PendingRatingItem.fromJson(Map<String, dynamic> json) {
    return PendingRatingItem(
      type: json['type']?.toString() ?? 'bidding_trip',
      id: int.tryParse('${json['id'] ?? 0}') ?? 0,
      contextType: json['context_type']?.toString() ?? 'bidding_trip',
      contextId: int.tryParse('${json['context_id'] ?? 0}') ?? 0,
      rateeUserId: int.tryParse('${json['ratee_user_id'] ?? 0}') ?? 0,
      title: json['title']?.toString() ?? 'قيّم الآن',
      subtitle: json['subtitle']?.toString() ?? '',
    );
  }
}

class PendingRatingService {
  PendingRatingService._();

  static Future<List<PendingRatingItem>> fetch() async {
    final token = CacheHelper.getData(key: 'token');
    if (token == null) return const [];

    try {
      final res = await Dio().get(
        ratingsPendingEP,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
          validateStatus: (s) => s != null && s < 600,
        ),
      );
      if (res.statusCode != 200 || res.data is! Map) return const [];
      final list = (res.data as Map)['data'];
      if (list is! List) return const [];
      return list
          .whereType<Map>()
          .map((e) => PendingRatingItem.fromJson(Map<String, dynamic>.from(e)))
          .where((e) => e.rateeUserId > 0 && e.contextId > 0)
          .toList();
    } catch (_) {
      return const [];
    }
  }

  /// يعرض أول تقييم معلّق إن وُجد.
  static Future<void> promptIfNeeded(BuildContext context) async {
    final items = await fetch();
    if (!context.mounted || items.isEmpty) return;
    final item = items.first;
    await showRateSheet(
      context,
      title: item.title,
      contextType: item.contextType,
      contextId: item.contextId,
      rateeUserId: item.rateeUserId,
    );
  }
}
