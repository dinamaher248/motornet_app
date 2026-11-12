import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:motorent/features/services/domain/entities/service_entities.dart';
import 'package:motorent/features/services/domain/repositories/service_repository.dart';

part 'custom_order_event.dart';
part 'custom_order_state.dart';

class CustomOrderBloc extends Bloc<CustomOrderEvent, CustomOrderState> {
  final ServiceRepository repository;

  CustomOrderBloc({required this.repository})
      : super(const CustomOrderState()) {
    on<SubmitCustomOrderEvent>(_onSubmit);
    on<RespondToVendorOfferEvent>(_onRespond);
  }

  Future<void> _onSubmit(
    SubmitCustomOrderEvent event,
    Emitter<CustomOrderState> emit,
  ) async {
    if (!event.params.hasRequestContent) {
      emit(state.copyWith(
        status: CustomOrderStatus.failure,
        message: 'اكتب طلبك أو ارفع صورة على الأقل',
      ));
      return;
    }

    emit(state.copyWith(
      status: CustomOrderStatus.submitting,
      clearMessage: true,
      clearOrder: true,
    ));

    final result = await repository.submitCustomOrder(event.params);
    result.fold(
      (failure) => emit(state.copyWith(
        status: CustomOrderStatus.failure,
        message: failure.message,
      )),
      (order) => emit(state.copyWith(
        status: CustomOrderStatus.submitSuccess,
        order: order,
        message: order.message ?? 'تم إرسال طلبك — بانتظار عرض من المتجر',
      )),
    );
  }

  Future<void> _onRespond(
    RespondToVendorOfferEvent event,
    Emitter<CustomOrderState> emit,
  ) async {
    emit(state.copyWith(
      status: CustomOrderStatus.responding,
      clearMessage: true,
    ));

    final result = await repository.respondToCustomOffer(
      orderId: event.orderId,
      action: event.action,
    );
    result.fold(
      (failure) => emit(state.copyWith(
        status: CustomOrderStatus.failure,
        message: failure.message,
      )),
      (order) => emit(state.copyWith(
        status: CustomOrderStatus.respondSuccess,
        order: order,
        message: event.action == 'reject' ? 'تم رفض العرض' : 'تم قبول العرض',
      )),
    );
  }
}
