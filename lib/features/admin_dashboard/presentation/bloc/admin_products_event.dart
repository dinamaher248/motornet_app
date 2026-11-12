part of 'admin_products_bloc.dart';

abstract class AdminProductsEvent extends Equatable {
  const AdminProductsEvent();
  @override
  List<Object?> get props => [];
}

class FetchAdminProductsEvent extends AdminProductsEvent {
  final int? vendorId;
  const FetchAdminProductsEvent({this.vendorId});
  @override
  List<Object?> get props => [vendorId];
}

class ToggleAdminProductEvent extends AdminProductsEvent {
  final int id;
  const ToggleAdminProductEvent(this.id);
  @override
  List<Object?> get props => [id];
}

class DeleteAdminProductEvent extends AdminProductsEvent {
  final int id;
  const DeleteAdminProductEvent(this.id);
  @override
  List<Object?> get props => [id];
}
