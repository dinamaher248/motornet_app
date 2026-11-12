import 'dart:io';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:motorent/features/vendor_interface/domain/entities/vendor_entities.dart';
import 'package:motorent/features/vendor_interface/domain/repositories/vendor_repository.dart';

part 'vendor_wallet_event.dart';
part 'vendor_wallet_state.dart';

class VendorWalletBloc extends Bloc<VendorWalletEvent, VendorWalletState> {
  final VendorRepository repository;

  VendorWalletBloc({required this.repository})
      : super(const VendorWalletState()) {
    on<FetchVendorWalletEvent>(_onFetch);
    on<UpdateVendorBillingModeEvent>(_onUpdateBillingMode);
    on<SubmitVendorSettlementEvent>(_onSubmit);
  }

  Future<void> _onFetch(
    FetchVendorWalletEvent event,
    Emitter<VendorWalletState> emit,
  ) async {
    emit(state.copyWith(
      status: VendorWalletStatus.loading,
      clearMessage: true,
    ));
    final result = await repository.fetchWallet();
    result.fold(
      (f) => emit(state.copyWith(
        status: VendorWalletStatus.failure,
        message: f.message,
      )),
      (wallet) => emit(state.copyWith(
        status: VendorWalletStatus.loaded,
        wallet: wallet,
      )),
    );
  }

  Future<void> _onUpdateBillingMode(
    UpdateVendorBillingModeEvent event,
    Emitter<VendorWalletState> emit,
  ) async {
    emit(state.copyWith(
      status: VendorWalletStatus.loading,
      clearMessage: true,
    ));
    final result = await repository.updateBillingMode(event.billingMode);
    result.fold(
      (f) => emit(state.copyWith(
        status: VendorWalletStatus.failure,
        message: f.message,
      )),
      (wallet) => emit(state.copyWith(
        status: VendorWalletStatus.loaded,
        wallet: wallet,
        message: 'تم تحديث طريقة الفوترة',
      )),
    );
  }

  Future<void> _onSubmit(
    SubmitVendorSettlementEvent event,
    Emitter<VendorWalletState> emit,
  ) async {
    emit(state.copyWith(status: VendorWalletStatus.submitting));
    final result = await repository.settleWallet(
      receipt: event.receipt,
      amount: event.amount,
    );
    result.fold(
      (f) => emit(state.copyWith(
        status: VendorWalletStatus.failure,
        message: f.message,
      )),
      (_) => emit(state.copyWith(
        status: VendorWalletStatus.settlementSuccess,
        message: 'تم استلام الطلب وهو بانتظار مراجعة الإدارة',
      )),
    );
  }
}
