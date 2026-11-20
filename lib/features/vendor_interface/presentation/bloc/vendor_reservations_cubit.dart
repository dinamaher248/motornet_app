import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:motorent/features/services/data/datasources/reservation_remote_data_source.dart';
import 'package:motorent/features/services/domain/entities/reservation_entities.dart';

enum VendorReservationsStatus { loading, loaded, failure }

class VendorReservationsState extends Equatable {
  final VendorReservationsStatus status;

  /// استفسارات جديدة بانتظار سعر التاجر (`pending_quote`).
  final List<ReservationBooking> incoming;

  /// أُرسل لها سعر وبانتظار قبول/رفض العميل (`quoted`).
  final List<ReservationBooking> awaitingCustomer;

  /// حجوزات مؤكدة (`GET /merchant/reservations?status=confirmed`).
  final List<ReservationBooking> confirmed;
  final int? busyId;
  final String? message;

  const VendorReservationsState({
    this.status = VendorReservationsStatus.loading,
    this.incoming = const [],
    this.awaitingCustomer = const [],
    this.confirmed = const [],
    this.busyId,
    this.message,
  });

  VendorReservationsState copyWith({
    VendorReservationsStatus? status,
    int? busyId,
    bool clearBusy = false,
    String? message,
  }) {
    return VendorReservationsState(
      status: status ?? this.status,
      incoming: incoming,
      awaitingCustomer: awaitingCustomer,
      confirmed: confirmed,
      busyId: clearBusy ? null : (busyId ?? this.busyId),
      message: message,
    );
  }

  @override
  List<Object?> get props =>
      [status, incoming, awaitingCustomer, confirmed, busyId, message];
}

class VendorReservationsCubit extends Cubit<VendorReservationsState> {
  final ReservationRemoteDataSource dataSource;

  VendorReservationsCubit({ReservationRemoteDataSource? dataSource})
      : dataSource = dataSource ?? ReservationRemoteDataSource(),
        super(const VendorReservationsState());

  static String _errorText(Object e) {
    final text = e.toString().replaceFirst('Exception: ', '').trim();
    return text.isEmpty ? 'حدث خطأ غير متوقع' : text;
  }

  Future<VendorReservationsState> _fetch({String? message}) async {
    final results = await Future.wait([
      dataSource.fetchMerchantReservations(),
      dataSource.fetchMerchantReservations(status: 'confirmed'),
    ]);
    final all = results[0];
    return VendorReservationsState(
      status: VendorReservationsStatus.loaded,
      incoming: all.where((b) => b.isPendingQuote).toList(),
      awaitingCustomer: all.where((b) => b.isQuoted).toList(),
      confirmed: results[1],
      message: message,
    );
  }

  Future<void> load({bool silent = false}) async {
    if (!silent) {
      emit(state.copyWith(status: VendorReservationsStatus.loading));
    }
    try {
      emit(await _fetch());
    } catch (e) {
      emit(
        VendorReservationsState(
          status: VendorReservationsStatus.failure,
          incoming: state.incoming,
          awaitingCustomer: state.awaitingCustomer,
          confirmed: state.confirmed,
          message: _errorText(e),
        ),
      );
    }
  }

  Future<void> markUnavailable(int id) async {
    if (state.busyId != null) return;
    emit(state.copyWith(busyId: id));
    try {
      final message = await dataSource.markUnavailable(id);
      emit(await _fetch(message: message));
    } catch (e) {
      emit(state.copyWith(clearBusy: true, message: _errorText(e)));
    }
  }

  Future<void> cancelBooking(int id) async {
    if (state.busyId != null) return;
    emit(state.copyWith(busyId: id));
    try {
      final message = await dataSource.cancelMerchantBooking(id);
      emit(await _fetch(message: message));
    } catch (e) {
      emit(state.copyWith(clearBusy: true, message: _errorText(e)));
    }
  }

  Future<void> sendQuote({
    required int id,
    double? price,
    required String details,
  }) async {
    if (state.busyId != null) return;
    emit(state.copyWith(busyId: id));
    try {
      final message = await dataSource.sendQuote(
        id: id,
        quotedPrice: price,
        quoteDetails: details,
      );
      emit(await _fetch(message: message));
    } catch (e) {
      emit(state.copyWith(clearBusy: true, message: _errorText(e)));
    }
  }
}
