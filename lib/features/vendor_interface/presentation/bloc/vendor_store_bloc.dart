import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:motorent/features/vendor_interface/domain/entities/vendor_entities.dart';
import 'package:motorent/features/vendor_interface/domain/repositories/vendor_repository.dart';

part 'vendor_store_event.dart';
part 'vendor_store_state.dart';

class VendorStoreBloc extends Bloc<VendorStoreEvent, VendorStoreState> {
  final VendorRepository repository;

  VendorStoreBloc({required this.repository})
      : super(const VendorStoreState()) {
    on<FetchVendorStoreEvent>(_onFetch);
    on<SubmitVendorStoreEvent>(_onSubmit);
  }

  Future<void> _onFetch(
    FetchVendorStoreEvent event,
    Emitter<VendorStoreState> emit,
  ) async {
    emit(state.copyWith(status: VendorStoreStatus.loading, clearMessage: true));
    final result = await repository.fetchStore();
    result.fold(
      (f) => emit(state.copyWith(
        status: VendorStoreStatus.failure,
        message: f.message,
      )),
      (store) => emit(state.copyWith(
        status: VendorStoreStatus.loaded,
        store: store,
      )),
    );
  }

  Future<void> _onSubmit(
    SubmitVendorStoreEvent event,
    Emitter<VendorStoreState> emit,
  ) async {
    emit(state.copyWith(status: VendorStoreStatus.saving, clearMessage: true));
    final result = await repository.updateStore(event.params);
    result.fold(
      (f) => emit(state.copyWith(
        status: VendorStoreStatus.failure,
        message: f.message,
      )),
      (store) => emit(state.copyWith(
        status: VendorStoreStatus.saved,
        store: store,
        message: 'تم حفظ بيانات النشاط بنجاح',
      )),
    );
  }
}
