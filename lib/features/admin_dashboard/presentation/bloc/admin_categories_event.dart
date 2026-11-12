part of 'admin_categories_bloc.dart';

abstract class AdminCategoriesEvent extends Equatable {
  const AdminCategoriesEvent();
  @override
  List<Object?> get props => [];
}

class FetchAdminCategoriesEvent extends AdminCategoriesEvent {
  const FetchAdminCategoriesEvent();
}

class CreateAdminCategoryEvent extends AdminCategoriesEvent {
  final String name;
  final String? slug;
  final String hubSection;
  const CreateAdminCategoryEvent({
    required this.name,
    this.slug,
    this.hubSection = 'orders',
  });
  @override
  List<Object?> get props => [name, slug, hubSection];
}

class UpdateAdminCategoryEvent extends AdminCategoriesEvent {
  final AdminCategory category;
  const UpdateAdminCategoryEvent(this.category);
  @override
  List<Object?> get props => [category];
}

class DeleteAdminCategoryEvent extends AdminCategoriesEvent {
  final int id;
  const DeleteAdminCategoryEvent(this.id);
  @override
  List<Object?> get props => [id];
}

class ToggleAdminCategoryEvent extends AdminCategoriesEvent {
  final int id;
  const ToggleAdminCategoryEvent(this.id);
  @override
  List<Object?> get props => [id];
}

class ReorderAdminCategoriesEvent extends AdminCategoriesEvent {
  final int oldIndex;
  final int newIndex;
  const ReorderAdminCategoriesEvent(this.oldIndex, this.newIndex);
  @override
  List<Object?> get props => [oldIndex, newIndex];
}
