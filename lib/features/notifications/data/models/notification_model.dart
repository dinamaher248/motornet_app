import 'package:motorent/features/notifications/domain/entities/app_notification.dart';

class NotificationModel extends AppNotification {
  const NotificationModel({
    required super.id,
    required super.title,
    required super.body,
    required super.type,
    required super.isRead,
    super.createdAt,
    super.action,
    super.refId,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    final isReadRaw = json['is_read'] ?? json['read'] ?? json['isRead'];
    final bool isRead;
    if (isReadRaw is bool) {
      isRead = isReadRaw;
    } else if (isReadRaw is num) {
      isRead = isReadRaw != 0;
    } else {
      isRead = isReadRaw?.toString() == '1' ||
          isReadRaw?.toString().toLowerCase() == 'true';
    }

    return NotificationModel(
      id: _asInt(json['id']),
      title: (json['title'] ?? json['head'] ?? 'إشعار').toString(),
      body: (json['body'] ?? json['description'] ?? json['desc'] ?? '')
          .toString(),
      type: (json['type'] ?? json['action'] ?? 'general').toString(),
      isRead: isRead,
      createdAt: _asDate(json['created_at'] ?? json['createdAt']),
      action: (json['action'] ?? json['type'])?.toString(),
      refId: (json['ref_id'] ??
              json['refId'] ??
              json['related_id'] ??
              json['url'])
          ?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'type': type,
      'is_read': isRead,
      'created_at': createdAt?.toIso8601String(),
      'action': action,
      'ref_id': refId,
    };
  }

  static int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static DateTime? _asDate(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }
}
