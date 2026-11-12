import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:motorent/features/admin_dashboard/domain/entities/admin_entities.dart';
import 'package:motorent/features/admin_dashboard/domain/repositories/admin_repository.dart';

part 'admin_products_event.dart';
part 'admin_products_state.dart';

class AdminProductsBloc extends Bloc<AdminProductsEvent, AdminProductsState> {
  final AdminRepository repository;

  AdminProductsBloc({required this.repository})
      : super(const AdminProductsState()) {
    on<FetchAdminProductsEvent>(_onFetch);
    on<ToggleAdminProductEvent>(_onToggle);
    on<DeleteAdminProductEvent>(_onDelete);
  }

  Future<void> _onFetch(
    FetchAdminProductsEvent event,
    Emitter<AdminProductsState> emit,
  ) async {
    emit(state.copyWith(
        status: AdminProductsStatus.loading,
        vendorId: event.vendorId,
        clearMessage: true));
    final result = await repository.fetchProducts(vendorId: event.vendorId);
    result.fold(
      (f) => emit(state.copyWith(
          status: AdminProductsStatus.failure, message: f.message)),
      (list) => emit(state.copyWith(
          status: AdminProductsStatus.loaded, products: list)),
    );
  }

  Future<void> _onToggle(
    ToggleAdminProductEvent event,
    Emitter<AdminProductsState> emit,
  ) async {
    emit(state.copyWith(actingId: event.id, clearMessage: true));
    final result = await repository.toggleProduct(event.id);
    result.fold(
      (f) => emit(state.copyWith(clearActing: true, message: f.message)),
      (p) {
        final list =
            state.products.map((e) => e.id == p.id ? p : e).toList();
        emit(state.copyWith(
          clearActing: true,
          products: list,
          message: p.isVisible ? 'تم تفعيل المنتج' : 'تم تعطيل المنتج',
        ));
      },
    );
  }

  Future<void> _onDelete(
    DeleteAdminProductEvent event,
    Emitter<AdminProductsState> emit,
  ) async {
    emit(state.copyWith(actingId: event.id, clearMessage: true));
    final result = await repository.deleteProduct(event.id);
    result.fold(
      (f) => emit(state.copyWith(clearActing: true, message: f.message)),
      (_) => emit(state.copyWith(
        clearActing: true,
        products: state.products.where((e) => e.id != event.id).toList(),
        message: 'تم حذف المنتج',
      )),
    );
  }
}
