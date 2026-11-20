import 'package:dio/dio.dart';
import 'package:motorent/data/local/cache_helper.dart';
import 'package:motorent/data/remote/url_api.dart';
import 'package:motorent/features/services/core/error/exceptions.dart';
import 'package:motorent/features/services/data/models/reservation_models.dart';
import 'package:motorent/features/services/domain/entities/reservation_entities.dart';

/// الحجوزات الديناميكية: جانب العميل (`/reservations/...`) وجانب التاجر
/// (`/merchant/reservations/...`).
class ReservationRemoteDataSource {
  final Dio dio;

  ReservationRemoteDataSource({Dio? dio}) : dio = dio ?? Dio();

  Options get _auth => Options(
        headers: {
          'Authorization': 'Bearer ${CacheHelper.getData(key: 'token')}',
          'Accept': 'application/json',
        },
        sendTimeout: const Duration(seconds: 40),
        receiveTimeout: const Duration(seconds: 40),
        validateStatus: (status) => status != null && status < 600,
      );

  // ─────────────────────────── العميل ───────────────────────────

  Future<List<ReservationField>> fetchFields(int categoryId) async {
    try {
      final res = await dio.get(
        reservationCategoryFieldsEP(categoryId),
        options: _auth,
      );
      _ensureOk(res, 'تعذر تحميل نموذج الحجز');
      final fields = _extractList(res.data, const ['data', 'fields'])
          .whereType<Map>()
          .map((e) =>
              ReservationFieldModel.fromJson(Map<String, dynamic>.from(e)))
          .where((f) => f.id > 0)
          .toList()
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      return fields;
    } on DioException catch (e) {
      throw _mapDio(e, 'تعذر تحميل نموذج الحجز');
    }
  }

  /// يرسل الاستفسار. [textAnswers] و[imageAnswers] مفتاحهما رقم الحقل.
  Future<String> createBooking({
    required int merchantId,
    required int categoryId,
    required Map<int, String> textAnswers,
    required Map<int, String> imageAnswers,
  }) async {
    try {
      final map = <String, dynamic>{
        'merchant_id': merchantId,
        'category_id': categoryId,
      };
      textAnswers.forEach((fieldId, value) {
        map['answers[$fieldId]'] = value;
      });
      for (final entry in imageAnswers.entries) {
        final path = entry.value;
        final ext = path.split('.').last.toLowerCase();
        final safe = ['jpg', 'jpeg', 'png', 'webp'].contains(ext) ? ext : 'jpg';
        map['answers[${entry.key}]'] = await MultipartFile.fromFile(
          path,
          filename:
              'answer_${entry.key}_${DateTime.now().millisecondsSinceEpoch}.$safe',
        );
      }

      final res = await dio.post(
        reservationBookingsEP,
        data: FormData.fromMap(map),
        options: _auth.copyWith(contentType: 'multipart/form-data'),
      );
      _ensureOk(res, 'تعذر إرسال الطلب');
      return _messageOrNull(res.data) ??
          'تم إرسال طلبك، وسيصلك السعر والتفاصيل قريباً';
    } on DioException catch (e) {
      throw _mapDio(e, 'تعذر إرسال الطلب');
    }
  }

  Future<List<ReservationBooking>> fetchMyBookings() async {
    try {
      final res = await dio.get(reservationMyBookingsEP, options: _auth);
      _ensureOk(res, 'تعذر تحميل حجوزاتك');
      return _parseBookings(res.data);
    } on DioException catch (e) {
      throw _mapDio(e, 'تعذر تحميل حجوزاتك');
    }
  }

  Future<ReservationBooking> fetchBooking(int id) async {
    try {
      final res = await dio.get(reservationBookingEP(id), options: _auth);
      _ensureOk(res, 'تعذر تحميل تفاصيل الحجز');
      return _parseBooking(res.data);
    } on DioException catch (e) {
      throw _mapDio(e, 'تعذر تحميل تفاصيل الحجز');
    }
  }

  Future<String> acceptQuote(int id) => _post(
        reservationAcceptEP(id),
        fallback: 'تعذر قبول العرض',
        success: 'تم تأكيد الحجز',
      );

  Future<String> cancelBooking(int id) => _post(
        reservationCustomerCancelEP(id),
        fallback: 'تعذر إلغاء الحجز',
        success: 'تم إلغاء الحجز',
      );

  Future<String> cancelMerchantBooking(int id) => _post(
        merchantReservationCancelEP(id),
        fallback: 'تعذر إلغاء الحجز',
        success: 'تم إلغاء الحجز',
      );

  Future<String> rejectQuote(int id) => _post(
        reservationRejectEP(id),
        fallback: 'تعذر رفض العرض',
        success: 'تم رفض العرض',
      );

  // ─────────────────────────── التاجر ───────────────────────────

  /// [status] اختياري: `confirmed` للحجوزات المؤكدة، وبدونه كل الاستفسارات.
  Future<List<ReservationBooking>> fetchMerchantReservations({
    String? status,
  }) async {
    try {
      final res = await dio.get(
        merchantReservationsEP,
        queryParameters: {
          if (status != null && status.isNotEmpty) 'status': status,
        },
        options: _auth,
      );
      _ensureOk(res, 'تعذر تحميل الحجوزات');
      return _parseBookings(res.data);
    } on DioException catch (e) {
      throw _mapDio(e, 'تعذر تحميل الحجوزات');
    }
  }

  Future<ReservationBooking> fetchMerchantReservation(int id) async {
    try {
      final res = await dio.get(merchantReservationEP(id), options: _auth);
      _ensureOk(res, 'تعذر تحميل تفاصيل الطلب');
      return _parseBooking(res.data);
    } on DioException catch (e) {
      throw _mapDio(e, 'تعذر تحميل تفاصيل الطلب');
    }
  }

  Future<String> markUnavailable(int id) => _post(
        merchantReservationUnavailableEP(id),
        fallback: 'تعذر تحديث الحالة',
        success: 'تم إبلاغ العميل بعدم التوفر',
      );

  Future<String> sendQuote({
    required int id,
    double? quotedPrice,
    required String quoteDetails,
  }) =>
      _post(
        merchantReservationQuoteEP(id),
        data: {
          if (quotedPrice != null && quotedPrice > 0)
            'quoted_price': quotedPrice,
          'quote_details': quoteDetails,
        },
        fallback: 'تعذر إرسال السعر',
        success: quotedPrice != null && quotedPrice > 0
            ? 'تم إرسال السعر والتفاصيل للعميل'
            : 'تم إبلاغ العميل بعدم التوفر',
      );

  // ─────────────────────────── مساعدات ───────────────────────────

  Future<String> _post(
    String url, {
    Map<String, dynamic>? data,
    required String fallback,
    required String success,
  }) async {
    try {
      final res = await dio.post(url, data: data, options: _auth);
      _ensureOk(res, fallback);
      return _messageOrNull(res.data) ?? success;
    } on DioException catch (e) {
      throw _mapDio(e, fallback);
    }
  }

  void _ensureOk(Response<dynamic> res, String fallback) {
    final code = res.statusCode ?? 0;
    if (code == 200 || code == 201) return;
    throw ServerException(_errorMessage(res.data, fallback), statusCode: code);
  }

  List<ReservationBooking> _parseBookings(dynamic data) {
    return _extractList(data, const ['data', 'bookings', 'reservations'])
        .whereType<Map>()
        .map((e) =>
            ReservationBookingModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  ReservationBooking _parseBooking(dynamic data) {
    if (data is Map) {
      final map = Map<String, dynamic>.from(data);
      final nested = map['data'] ?? map['booking'] ?? map['reservation'];
      if (nested is Map) {
        return ReservationBookingModel.fromJson(
          Map<String, dynamic>.from(nested),
        );
      }
      return ReservationBookingModel.fromJson(map);
    }
    throw const ServerException('استجابة غير متوقعة من السيرفر');
  }

  /// يدعم `{data: [...]}` و`{data: {data: [...]}}` (pagination) والقائمة المباشرة.
  List<dynamic> _extractList(dynamic data, List<String> keys) {
    if (data is List) return data;
    if (data is Map) {
      for (final key in keys) {
        final value = data[key];
        if (value is List) return value;
        if (value is Map && value['data'] is List) {
          return value['data'] as List;
        }
        // {data: {fields: [...]}} — نبحث داخل الخريطة عن أي مفتاح مطلوب يحمل قائمة.
        if (value is Map) {
          for (final inner in keys) {
            if (inner != key && value[inner] is List) {
              return value[inner] as List;
            }
          }
        }
      }
    }
    return const [];
  }

  String? _messageOrNull(dynamic data) {
    if (data is Map) {
      final message = data['message'];
      if (message is String && message.trim().isNotEmpty) return message;
    }
    return null;
  }

  /// رسالة السيرفر + أول خطأ تحقق (422) إن وُجد.
  String _errorMessage(dynamic data, String fallback) {
    if (data is Map) {
      final errors = data['errors'];
      if (errors is Map && errors.isNotEmpty) {
        final first = errors.values.first;
        if (first is List && first.isNotEmpty) return first.first.toString();
        if (first is String && first.isNotEmpty) return first;
      }
      final message = _messageOrNull(data);
      if (message != null) return message;
    }
    return fallback;
  }

  Exception _mapDio(DioException e, String fallback) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.connectionError) {
      return const NetworkException();
    }
    if (e.response != null) {
      return ServerException(
        _errorMessage(e.response?.data, fallback),
        statusCode: e.response?.statusCode,
      );
    }
    return NetworkException(e.message ?? fallback);
  }
}
