import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:motorent/features/services/data/datasources/reservation_remote_data_source.dart';
import 'package:motorent/features/services/domain/entities/reservation_entities.dart';

String _errorText(Object e) {
  final text = e.toString().replaceFirst('Exception: ', '').trim();
  return text.isEmpty ? 'حدث خطأ غير متوقع' : text;
}

// ───────────────────── نموذج الحجز الديناميكي ─────────────────────

enum ReservationFormStatus { loading, ready, submitting, submitted, failure }

class ReservationFormState extends Equatable {
  final ReservationFormStatus status;
  final List<ReservationField> fields;
  final String? message;

  const ReservationFormState({
    this.status = ReservationFormStatus.loading,
    this.fields = const [],
    this.message,
  });

  ReservationFormState copyWith({
    ReservationFormStatus? status,
    List<ReservationField>? fields,
    String? message,
  }) {
    return ReservationFormState(
      status: status ?? this.status,
      fields: fields ?? this.fields,
      message: message,
    );
  }

  @override
  List<Object?> get props => [status, fields, message];
}

class ReservationFormCubit extends Cubit<ReservationFormState> {
  final ReservationRemoteDataSource dataSource;

  ReservationFormCubit({ReservationRemoteDataSource? dataSource})
      : dataSource = dataSource ?? ReservationRemoteDataSource(),
        super(const ReservationFormState());

  Future<void> load(int categoryId) async {
    emit(const ReservationFormState(status: ReservationFormStatus.loading));
    try {
      final fields = await dataSource.fetchFields(categoryId);
      emit(
        ReservationFormState(
          status: ReservationFormStatus.ready,
          fields: fields,
        ),
      );
    } catch (e) {
      emit(
        ReservationFormState(
          status: ReservationFormStatus.failure,
          message: _errorText(e),
        ),
      );
    }
  }

  Future<void> submit({
    required int merchantId,
    required int categoryId,
    required Map<int, String> textAnswers,
    required Map<int, String> imageAnswers,
  }) async {
    if (state.status == ReservationFormStatus.submitting) return;
    final fields = state.fields;
    emit(
      ReservationFormState(
        status: ReservationFormStatus.submitting,
        fields: fields,
      ),
    );
    try {
      final message = await dataSource.createBooking(
        merchantId: merchantId,
        categoryId: categoryId,
        textAnswers: textAnswers,
        imageAnswers: imageAnswers,
      );
      emit(
        ReservationFormState(
          status: ReservationFormStatus.submitted,
          fields: fields,
          message: message,
        ),
      );
    } catch (e) {
      // نرجع للحالة الجاهزة مع رسالة الخطأ كي لا يضيع ما كتبه العميل.
      emit(
        ReservationFormState(
          status: ReservationFormStatus.failure,
          fields: fields,
          message: _errorText(e),
        ),
      );
    }
  }
}

// ───────────────────────── حجوزاتي ─────────────────────────

enum MyBookingsStatus { loading, loaded, failure }

class MyBookingsState extends Equatable {
  final MyBookingsStatus status;
  final List<ReservationBooking> bookings;
  final int? busyId;
  final String? message;

  const MyBookingsState({
    this.status = MyBookingsStatus.loading,
    this.bookings = const [],
    this.busyId,
    this.message,
  });

  MyBookingsState copyWith({
    MyBookingsStatus? status,
    List<ReservationBooking>? bookings,
    int? busyId,
    bool clearBusy = false,
    String? message,
  }) {
    return MyBookingsState(
      status: status ?? this.status,
      bookings: bookings ?? this.bookings,
      busyId: clearBusy ? null : (busyId ?? this.busyId),
      message: message,
    );
  }

  @override
  List<Object?> get props => [status, bookings, busyId, message];
}

class MyBookingsCubit extends Cubit<MyBookingsState> {
  final ReservationRemoteDataSource dataSource;

  MyBookingsCubit({ReservationRemoteDataSource? dataSource})
      : dataSource = dataSource ?? ReservationRemoteDataSource(),
        super(const MyBookingsState());

  Future<void> load({bool silent = false}) async {
    if (!silent) {
      emit(state.copyWith(status: MyBookingsStatus.loading));
    }
    try {
      final list = await dataSource.fetchMyBookings();
      emit(
        MyBookingsState(
          status: MyBookingsStatus.loaded,
          bookings: list,
        ),
      );
    } catch (e) {
      emit(
        MyBookingsState(
          status: MyBookingsStatus.failure,
          bookings: state.bookings,
          message: _errorText(e),
        ),
      );
    }
  }

  Future<void> accept(int id) => _respond(id, accept: true);

  Future<void> reject(int id) => _respond(id, accept: false);

  Future<void> cancel(int id) async {
    if (state.busyId != null) return;
    emit(state.copyWith(busyId: id));
    try {
      final message = await dataSource.cancelBooking(id);
      final list = await dataSource.fetchMyBookings();
      emit(MyBookingsState(
        status: MyBookingsStatus.loaded,
        bookings: list,
        message: message,
      ));
    } catch (e) {
      emit(state.copyWith(clearBusy: true, message: _errorText(e)));
    }
  }

  Future<void> _respond(int id, {required bool accept}) async {
    if (state.busyId != null) return;
    emit(state.copyWith(busyId: id));
    try {
      final message = accept
          ? await dataSource.acceptQuote(id)
          : await dataSource.rejectQuote(id);
      final list = await dataSource.fetchMyBookings();
      emit(
        MyBookingsState(
          status: MyBookingsStatus.loaded,
          bookings: list,
          message: message,
        ),
      );
    } catch (e) {
      emit(state.copyWith(clearBusy: true, message: _errorText(e)));
    }
  }
}
