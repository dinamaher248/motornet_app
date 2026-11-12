import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:motorent/features/vendor_interface/domain/entities/vendor_entities.dart';
import 'package:motorent/features/vendor_interface/domain/repositories/vendor_repository.dart';

part 'vendor_products_event.dart';
part 'vendor_products_state.dart';

class VendorProductsBloc
    extends Bloc<VendorProductsEvent, VendorProductsState> {
  final VendorRepository repository;

  VendorProductsBloc({required this.repository})
      : super(const VendorProductsState()) {
    on<FetchVendorProductsEvent>(_onFetch);
    on<ToggleVendorProductEvent>(_onToggle);
    on<CreateVendorProductEvent>(_onCreate);
    on<UpdateVendorProductEvent>(_onUpdate);
    on<DeleteVendorProductEvent>(_onDelete);
  }

  Future<void> _onFetch(
    FetchVendorProductsEvent event,
    Emitter<VendorProductsState> emit,
  ) async {
    emit(state.copyWith(
      status: VendorProductsStatus.loading,
      clearMessage: true,
    ));
    final result = await repository.fetchProducts();
    result.fold(
      (f) => emit(state.copyWith(
        status: VendorProductsStatus.failure,
        message: f.message,
      )),
      (products) => emit(state.copyWith(
        status: VendorProductsStatus.loaded,
        products: products,
      )),
    );
  }

  Future<void> _onToggle(
    ToggleVendorProductEvent event,
    Emitter<VendorProductsState> emit,
  ) async {
    final result = await repository.toggleProduct(event.productId);
    result.fold(
      (f) => emit(state.copyWith(message: f.message)),
      (updated) {
        final list = state.products
            .map((p) => p.id == updated.id ? updated : p)
            .toList();
        emit(state.copyWith(
          products: list,
          status: VendorProductsStatus.loaded,
        ));
      },
    );
  }

  Future<void> _onCreate(
    CreateVendorProductEvent event,
    Emitter<VendorProductsState> emit,
  ) async {
    if (state.products.length >= 10) {
      emit(state.copyWith(message: 'الحد الأقصى 10 منتجات'));
      return;
    }
    emit(state.copyWith(status: VendorProductsStatus.creating));
    final result = await repository.createProduct(event.params);
    result.fold(
      (f) => emit(state.copyWith(
        status: VendorProductsStatus.failure,
        message: f.message,
      )),
      (product) => emit(state.copyWith(
        status: VendorProductsStatus.created,
        products: [...state.products, product],
        message: 'تم إضافة المنتج بنجاح',
      )),
    );
  }

  Future<void> _onUpdate(
    UpdateVendorProductEvent event,
    Emitter<VendorProductsState> emit,
  ) async {
    emit(state.copyWith(status: VendorProductsStatus.updating));
    final result = await repository.updateProduct(event.params);
    result.fold(
      (f) => emit(state.copyWith(
        status: VendorProductsStatus.failure,
        message: f.message,
      )),
      (updated) {
        final list = state.products
            .map((p) => p.id == updated.id ? updated : p)
            .toList();
        emit(state.copyWith(
          status: VendorProductsStatus.updated,
          products: list,
          message: 'تم تحديث المنتج بنجاح',
        ));
      },
    );
  }

  Future<void> _onDelete(
    DeleteVendorProductEvent event,
    Emitter<VendorProductsState> emit,
  ) async {
    emit(state.copyWith(status: VendorProductsStatus.deleting));
    final result = await repository.deleteProduct(event.productId);
    result.fold(
      (f) => emit(state.copyWith(
        status: VendorProductsStatus.failure,
        message: f.message,
      )),
      (_) {
        final list =
            state.products.where((p) => p.id != event.productId).toList();
        emit(state.copyWith(
          status: VendorProductsStatus.loaded,
          products: list,
          message: 'تم حذف المنتج',
        ));
      },
    );
  }
}
