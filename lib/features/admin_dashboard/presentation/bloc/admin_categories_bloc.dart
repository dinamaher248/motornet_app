import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:motorent/features/admin_dashboard/domain/entities/admin_entities.dart';
import 'package:motorent/features/admin_dashboard/domain/repositories/admin_repository.dart';

part 'admin_categories_event.dart';
part 'admin_categories_state.dart';

class AdminCategoriesBloc
    extends Bloc<AdminCategoriesEvent, AdminCategoriesState> {
  final AdminRepository repository;

  AdminCategoriesBloc({required this.repository})
      : super(const AdminCategoriesState()) {
    on<FetchAdminCategoriesEvent>(_onFetch);
    on<CreateAdminCategoryEvent>(_onCreate);
    on<UpdateAdminCategoryEvent>(_onUpdate);
    on<DeleteAdminCategoryEvent>(_onDelete);
    on<ToggleAdminCategoryEvent>(_onToggle);
    on<ReorderAdminCategoriesEvent>(_onReorder);
  }

  Future<void> _onFetch(
    FetchAdminCategoriesEvent event,
    Emitter<AdminCategoriesState> emit,
  ) async {
    emit(state.copyWith(
        status: AdminCategoriesStatus.loading, clearMessage: true));
    final result = await repository.fetchCategories();
    result.fold(
      (f) => emit(state.copyWith(
          status: AdminCategoriesStatus.failure, message: f.message)),
      (list) => emit(state.copyWith(
          status: AdminCategoriesStatus.loaded, categories: list)),
    );
  }

  Future<void> _onCreate(
    CreateAdminCategoryEvent event,
    Emitter<AdminCategoriesState> emit,
  ) async {
    emit(state.copyWith(busy: true, clearMessage: true));
    final result =
        await repository.createCategory(
      name: event.name,
      slug: event.slug,
      hubSection: event.hubSection,
    );
    result.fold(
      (f) => emit(state.copyWith(busy: false, message: f.message)),
      (cat) => emit(state.copyWith(
        busy: false,
        categories: [...state.categories, cat],
        message: 'تمت إضافة القسم',
      )),
    );
  }

  Future<void> _onUpdate(
    UpdateAdminCategoryEvent event,
    Emitter<AdminCategoriesState> emit,
  ) async {
    emit(state.copyWith(busy: true, clearMessage: true));
    final result = await repository.updateCategory(event.category);
    result.fold(
      (f) => emit(state.copyWith(busy: false, message: f.message)),
      (cat) {
        final list =
            state.categories.map((c) => c.id == cat.id ? cat : c).toList();
        emit(state.copyWith(
            busy: false, categories: list, message: 'تم تعديل القسم'));
      },
    );
  }

  Future<void> _onDelete(
    DeleteAdminCategoryEvent event,
    Emitter<AdminCategoriesState> emit,
  ) async {
    emit(state.copyWith(busy: true, clearMessage: true));
    final result = await repository.deleteCategory(event.id);
    result.fold(
      (f) => emit(state.copyWith(busy: false, message: f.message)),
      (_) => emit(state.copyWith(
        busy: false,
        categories: state.categories.where((c) => c.id != event.id).toList(),
        message: 'تم حذف القسم',
      )),
    );
  }

  Future<void> _onToggle(
    ToggleAdminCategoryEvent event,
    Emitter<AdminCategoriesState> emit,
  ) async {
    emit(state.copyWith(busy: true, clearMessage: true));
    final result = await repository.toggleCategory(event.id);
    result.fold(
      (f) => emit(state.copyWith(busy: false, message: f.message)),
      (cat) {
        final list =
            state.categories.map((c) => c.id == cat.id ? cat : c).toList();
        emit(state.copyWith(busy: false, categories: list));
      },
    );
  }

  Future<void> _onReorder(
    ReorderAdminCategoriesEvent event,
    Emitter<AdminCategoriesState> emit,
  ) async {
    final old = List<AdminCategory>.from(state.categories);
    final item = old.removeAt(event.oldIndex);
    final newIndex =
        event.newIndex > event.oldIndex ? event.newIndex - 1 : event.newIndex;
    old.insert(newIndex, item);
    emit(state.copyWith(categories: old));
    final result =
        await repository.reorderCategories(old.map((e) => e.id).toList());
    result.fold(
      (f) => emit(state.copyWith(
        categories: state.categories,
        message: f.message,
      )),
      (_) {},
    );
  }
}
