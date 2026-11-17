import 'dart:convert';

import 'package:motorent/features/services/domain/entities/reservation_entities.dart';

int _asInt(dynamic v) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse(v?.toString() ?? '') ?? 0;
}

double? _asDouble(dynamic v) {
  if (v == null) return null;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString());
}

bool _asBool(dynamic v) {
  if (v is bool) return v;
  if (v is num) return v != 0;
  final s = v?.toString().toLowerCase().trim();
  return s == '1' || s == 'true';
}

Map<String, dynamic>? _asMap(dynamic v) =>
    v is Map ? Map<String, dynamic>.from(v) : null;

String? _nonEmpty(dynamic v) {
  final s = v?.toString().trim() ?? '';
  return s.isEmpty ? null : s;
}

class ReservationFieldModel {
  ReservationFieldModel._();

  static ReservationFieldType parseType(dynamic raw) {
    switch (raw?.toString().toLowerCase().trim()) {
      case 'number':
      case 'numeric':
      case 'integer':
        return ReservationFieldType.number;
      case 'image':
      case 'file':
      case 'photo':
        return ReservationFieldType.image;
      case 'select':
      case 'dropdown':
        return ReservationFieldType.select;
      case 'radio':
        return ReservationFieldType.radio;
      default:
        return ReservationFieldType.text;
    }
  }

  /// الخيارات قد تأتي كقائمة نصوص أو قائمة {label,value} أو JSON نصي أو نص مفصول بفواصل.
  static List<String> parseOptions(dynamic raw) {
    dynamic value = raw;
    if (value is String) {
      final trimmed = value.trim();
      if (trimmed.isEmpty) return const [];
      if (trimmed.startsWith('[')) {
        try {
          value = jsonDecode(trimmed);
        } catch (_) {
          value = trimmed;
        }
      }
    }
    if (value is List) {
      return value
          .map((e) {
            if (e is Map) {
              return (e['label'] ?? e['name'] ?? e['value'] ?? '').toString();
            }
            return e.toString();
          })
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }
    if (value is String) {
      return value
          .split(RegExp(r'[,\n،]'))
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }
    return const [];
  }

  static ReservationField fromJson(Map<String, dynamic> json) {
    return ReservationField(
      id: _asInt(json['id']),
      label: (json['label'] ?? json['name'] ?? '').toString(),
      type: parseType(json['field_type'] ?? json['type']),
      options: parseOptions(json['options']),
      isRequired: _asBool(json['is_required'] ?? json['required']),
      sortOrder: _asInt(json['sort_order']),
    );
  }
}

class ReservationBookingModel {
  ReservationBookingModel._();

  static List<ReservationAnswer> _parseAnswers(dynamic raw) {
    final out = <ReservationAnswer>[];
    if (raw is List) {
      for (final item in raw) {
        if (item is! Map) continue;
        final m = Map<String, dynamic>.from(item);
        final field = _asMap(m['field']);
        final label = (m['label'] ??
                m['field_label'] ??
                field?['label'] ??
                m['name'] ??
                '')
            .toString();
        final type = ReservationFieldModel.parseType(
          m['field_type'] ?? m['type'] ?? field?['field_type'],
        );
        final imageRaw = _nonEmpty(m['image'] ?? m['image_path'] ?? m['file']);
        final valueRaw = _nonEmpty(
          m['value'] ?? m['answer'] ?? m['answer_text'] ?? m['text'],
        );
        final isImage = type == ReservationFieldType.image || imageRaw != null;
        final value = imageRaw ?? valueRaw ?? '';
        if (label.isEmpty && value.isEmpty) continue;
        out.add(ReservationAnswer(label: label, value: value, isImage: isImage));
      }
    } else if (raw is Map) {
      raw.forEach((k, v) {
        final value = v?.toString() ?? '';
        if (value.isEmpty) return;
        out.add(ReservationAnswer(label: k.toString(), value: value));
      });
    }
    return out;
  }

  static ReservationBooking fromJson(Map<String, dynamic> json) {
    final merchant = _asMap(json['merchant']) ?? _asMap(json['store']);
    final customer = _asMap(json['customer']) ?? _asMap(json['user']);
    final category = _asMap(json['category']);

    return ReservationBooking(
      id: _asInt(json['id']),
      status: (json['status'] ?? 'pending_quote').toString().toLowerCase(),
      merchantId: json['merchant_id'] != null
          ? _asInt(json['merchant_id'])
          : (merchant != null ? _asInt(merchant['id']) : null),
      merchantName: (merchant?['name'] ??
              json['merchant_name'] ??
              json['store_name'] ??
              '')
          .toString(),
      merchantPhone: _nonEmpty(merchant?['phone'] ?? json['merchant_phone']),
      categoryName:
          _nonEmpty(category?['name'] ?? json['category_name']),
      customerName: _nonEmpty(customer?['name'] ?? json['customer_name']),
      customerPhone: _nonEmpty(customer?['phone'] ?? json['customer_phone']),
      quotedPrice: _asDouble(json['quoted_price']),
      quoteDetails: _nonEmpty(json['quote_details']),
      answers: _parseAnswers(json['answers']),
      createdAt: _nonEmpty(json['created_at']),
    );
  }
}
