import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:motorent/features/services/domain/entities/service_entities.dart';
import 'package:motorent/features/services/domain/repositories/service_repository.dart';

part 'service_event.dart';
part 'service_state.dart';

class ServiceBloc extends Bloc<ServiceEvent, ServiceState> {
  final ServiceRepository repository;

  Store? _currentStore;

  ServiceBloc({required this.repository}) : super(const ServiceInitial()) {
    on<FetchStoresEvent>(_onFetchStores);
    on<FetchStoreDetailsEvent>(_onFetchStoreDetails);
    on<SubmitServiceOrderEvent>(_onSubmitOrder);
  }

  Future<void> _onFetchStores(
    FetchStoresEvent event,
    Emitter<ServiceState> emit,
  ) async {
    emit(const ServiceLoading());
    final result = await repository.fetchStores(
      category: event.category,
      lat: event.lat,
      lng: event.lng,
      listingKind: event.listingKind,
    );
    result.fold(
      (failure) => emit(ServiceError(failure.message)),
      (stores) => emit(StoresLoaded(category: event.category, stores: stores)),
    );
  }

  Future<void> _onFetchStoreDetails(
    FetchStoreDetailsEvent event,
    Emitter<ServiceState> emit,
  ) async {
    emit(const ServiceLoading());
    final result = await repository.fetchStoreDetails(
      event.storeId,
      lat: event.lat,
      lng: event.lng,
    );
    result.fold(
      (failure) => emit(ServiceError(failure.message)),
      (store) {
        _currentStore = store;
        emit(StoreDetailsLoaded(store));
      },
    );
  }

  Future<void> _onSubmitOrder(
    SubmitServiceOrderEvent event,
    Emitter<ServiceState> emit,
  ) async {
    emit(OrderSubmitting(store: _currentStore));
    final result = await repository.checkout(event.params);
    result.fold(
      (failure) {
        emit(OrderSubmitError(failure.message, store: _currentStore));
        if (_currentStore != null) {
          emit(StoreDetailsLoaded(_currentStore!));
        }
      },
      (order) => emit(OrderSubmitSuccess(order)),
    );
  }
}
