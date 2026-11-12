import 'dart:io';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:motorent/features/driver_interface/domain/entities/driver_entities.dart';
import 'package:motorent/features/driver_interface/domain/repositories/driver_repository.dart';

part 'driver_wallet_event.dart';
part 'driver_wallet_state.dart';

class DriverWalletBloc extends Bloc<DriverWalletEvent, DriverWalletState> {
  final DriverRepository repository;

  DriverWalletBloc({required this.repository})
      : super(const DriverWalletState()) {
    on<FetchWalletStats>(_onFetch);
    on<UpdateDriverBillingModeEvent>(_onUpdateBillingMode);
    on<SubmitSettlementEvent>(_onSubmit);
  }

  Future<void> _onUpdateBillingMode(
    UpdateDriverBillingModeEvent event,
    Emitter<DriverWalletState> emit,
  ) async {
    emit(state.copyWith(status: DriverWalletStatus.loading, clearMessage: true));
    final result = await repository.updateBillingMode(event.billingMode);
    result.fold(
      (failure) => emit(state.copyWith(
        status: DriverWalletStatus.failure,
        message: failure.message,
      )),
      (wallet) => emit(state.copyWith(
        status: DriverWalletStatus.loaded,
        wallet: wallet,
        message: 'تم تحديث طريقة الفوترة',
      )),
    );
  }

  Future<void> _onFetch(
    FetchWalletStats event,
    Emitter<DriverWalletState> emit,
  ) async {
    emit(state.copyWith(status: DriverWalletStatus.loading, clearMessage: true));
    final result = await repository.fetchWallet();
    result.fold(
      (failure) => emit(state.copyWith(
        status: DriverWalletStatus.failure,
        message: failure.message,
      )),
      (wallet) => emit(state.copyWith(
        status: DriverWalletStatus.loaded,
        wallet: wallet,
      )),
    );
  }

  Future<void> _onSubmit(
    SubmitSettlementEvent event,
    Emitter<DriverWalletState> emit,
  ) async {
    emit(state.copyWith(
      status: DriverWalletStatus.submitting,
      clearMessage: true,
    ));
    final result = await repository.settleWallet(
      receipt: event.receipt,
      amount: event.amount,
    );
    result.fold(
      (failure) => emit(state.copyWith(
        status: DriverWalletStatus.failure,
        message: failure.message,
      )),
      (_) => emit(state.copyWith(
        status: DriverWalletStatus.settlementSuccess,
        message: 'تم استلام الطلب وهو بانتظار مراجعة الإدارة',
      )),
    );
  }
}
