part of 'admin_commissions_bloc.dart';

abstract class AdminCommissionsEvent extends Equatable {
  const AdminCommissionsEvent();
  @override
  List<Object?> get props => [];
}

class LoadAdminCommissionsEvent extends AdminCommissionsEvent {
  const LoadAdminCommissionsEvent();
}

class UpdateCommissionEnabledEvent extends AdminCommissionsEvent {
  final bool enabled;
  const UpdateCommissionEnabledEvent(this.enabled);
  @override
  List<Object?> get props => [enabled];
}

class UpdateCommissionFieldsEvent extends AdminCommissionsEvent {
  final double? driverPercent;
  final double? vendorPercent;
  final double? debtLimit;
  final bool? vendorOrdersCommissionEnabled;
  final double? vendorOrdersCommissionPercent;
  final bool? vendorOrdersFixedFeeEnabled;
  final double? vendorOrdersFixedFeeAmount;
  const UpdateCommissionFieldsEvent({
    this.driverPercent,
    this.vendorPercent,
    this.debtLimit,
    this.vendorOrdersCommissionEnabled,
    this.vendorOrdersCommissionPercent,
    this.vendorOrdersFixedFeeEnabled,
    this.vendorOrdersFixedFeeAmount,
  });
  @override
  List<Object?> get props => [
        driverPercent,
        vendorPercent,
        debtLimit,
        vendorOrdersCommissionEnabled,
        vendorOrdersCommissionPercent,
        vendorOrdersFixedFeeEnabled,
        vendorOrdersFixedFeeAmount,
      ];
}

class SaveCommissionSettingsEvent extends AdminCommissionsEvent {
  const SaveCommissionSettingsEvent();
}

class UpdateVendorOrdersCommissionEnabledEvent extends AdminCommissionsEvent {
  final bool enabled;
  const UpdateVendorOrdersCommissionEnabledEvent(this.enabled);
  @override
  List<Object?> get props => [enabled];
}

class UpdateVendorOrdersFixedFeeEnabledEvent extends AdminCommissionsEvent {
  final bool enabled;
  const UpdateVendorOrdersFixedFeeEnabledEvent(this.enabled);
  @override
  List<Object?> get props => [enabled];
}

class HandleSettlementEvent extends AdminCommissionsEvent {
  final int id;
  final String action;
  const HandleSettlementEvent({required this.id, required this.action});
  @override
  List<Object?> get props => [id, action];
}
