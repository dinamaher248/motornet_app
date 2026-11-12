import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:motorent/features/vendor_interface/domain/entities/vendor_entities.dart';
import 'package:motorent/features/vendor_interface/domain/repositories/vendor_repository.dart';

part 'vendor_orders_event.dart';
part 'vendor_orders_state.dart';

class VendorOrdersBloc extends Bloc<VendorOrdersEvent, VendorOrdersState> {
  final VendorRepository repository;

  VendorOrdersBloc({required this.repository})
      : super(const VendorOrdersState()) {
    on<FetchVendorOrdersEvent>(_onFetch);
    on<HandleVendorOrderEvent>(_onHandle);
    on<SendCustomOfferEvent>(_onSendOffer);
  }

  Future<void> _onFetch(
    FetchVendorOrdersEvent event,
    Emitter<VendorOrdersState> emit,
  ) async {
    emit(state.copyWith(
      status: VendorOrdersStatus.loading,
      clearMessage: true,
    ));
    final result = await repository.fetchOrders();
    result.fold(
      (f) => emit(state.copyWith(
        status: VendorOrdersStatus.failure,
        message: f.message,
      )),
      (orders) => emit(state.copyWith(
        status: VendorOrdersStatus.loaded,
        orders: orders,
      )),
    );
  }

  Future<void> _onHandle(
    HandleVendorOrderEvent event,
    Emitter<VendorOrdersState> emit,
  ) async {
    emit(state.copyWith(
      handlingOrderId: event.orderId,
      clearMessage: true,
    ));
    final result = await repository.handleOrder(
      orderId: event.orderId,
      action: event.action,
      orderType: event.orderType,
    );
    result.fold(
      (f) => emit(state.copyWith(
        clearHandling: true,
        message: f.message,
        status: VendorOrdersStatus.failure,
      )),
      (_) async {
        final refresh = await repository.fetchOrders();
        refresh.fold(
          (f) => emit(state.copyWith(
            clearHandling: true,
            status: VendorOrdersStatus.loaded,
            message: event.action.contains('reject')
                ? 'تم رفض الطلب'
                : 'تم قبول الطلب وجاري التجهيز',
          )),
          (orders) => emit(state.copyWith(
            clearHandling: true,
            orders: orders,
            status: VendorOrdersStatus.loaded,
            message: event.action.contains('reject')
                ? 'تم رفض الطلب'
                : 'تم قبول الطلب وجاري التجهيز',
          )),
        );
      },
    );
  }

  Future<void> _onSendOffer(
    SendCustomOfferEvent event,
    Emitter<VendorOrdersState> emit,
  ) async {
    emit(state.copyWith(
      handlingOrderId: event.params.orderId,
      clearMessage: true,
    ));
    final result = await repository.sendCustomOffer(event.params);
    result.fold(
      (f) => emit(state.copyWith(
        clearHandling: true,
        message: f.message,
        status: VendorOrdersStatus.failure,
      )),
      (order) {
        final list = state.orders
            .map((o) => o.id == order.id ? order : o)
            .toList();
        emit(state.copyWith(
          clearHandling: true,
          orders: list,
          status: VendorOrdersStatus.loaded,
          message: 'تم إرسال العرض بنجاح',
        ));
      },
    );
  }
}
