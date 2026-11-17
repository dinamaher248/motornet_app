import 'package:equatable/equatable.dart';

/// أنواع حقول نموذج الحجز الديناميكي (من لوحة الإدارة).
enum ReservationFieldType { text, number, image, select, radio }

class ReservationField extends Equatable {
  final int id;
  final String label;
  final ReservationFieldType type;
  final List<String> options;
  final bool isRequired;
  final int sortOrder;

  const ReservationField({
    required this.id,
    required this.label,
    required this.type,
    this.options = const [],
    this.isRequired = false,
    this.sortOrder = 0,
  });

  @override
  List<Object?> get props => [id, label, type, options, isRequired, sortOrder];
}

/// إجابة العميل على حقل واحد (للعرض عند التاجر / في حجوزاتي).
class ReservationAnswer extends Equatable {
  final String label;
  final String value;
  final bool isImage;

  const ReservationAnswer({
    required this.label,
    required this.value,
    this.isImage = false,
  });

  @override
  List<Object?> get props => [label, value, isImage];
}

/// حجز / استفسار سعر.
/// الحالات: pending_quote → quoted → confirmed | rejected، أو unavailable.
class ReservationBooking extends Equatable {
  final int id;
  final String status;
  final int? merchantId;
  final String merchantName;
  final String? merchantPhone;
  final String? categoryName;
  final String? customerName;
  final String? customerPhone;
  final double? quotedPrice;
  final String? quoteDetails;
  final List<ReservationAnswer> answers;
  final String? createdAt;

  const ReservationBooking({
    required this.id,
    required this.status,
    this.merchantId,
    this.merchantName = '',
    this.merchantPhone,
    this.categoryName,
    this.customerName,
    this.customerPhone,
    this.quotedPrice,
    this.quoteDetails,
    this.answers = const [],
    this.createdAt,
  });

  bool get isPendingQuote => status == 'pending_quote' || status == 'pending';
  bool get isQuoted => status == 'quoted';
  bool get isConfirmed => status == 'confirmed';
  bool get isRejected => status == 'rejected';
  bool get isUnavailable => status == 'unavailable';

  String get statusLabel {
    if (isPendingQuote) return 'بانتظار رد المكان';
    if (isQuoted) return 'وصلك عرض سعر';
    if (isConfirmed) return 'تم تأكيد الحجز';
    if (isRejected) return 'تم رفض العرض';
    if (isUnavailable) return 'غير متوفر حالياً';
    return status;
  }

  @override
  List<Object?> get props => [
        id,
        status,
        merchantId,
        merchantName,
        merchantPhone,
        categoryName,
        customerName,
        customerPhone,
        quotedPrice,
        quoteDetails,
        answers,
        createdAt,
      ];
}
