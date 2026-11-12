part of 'admin_categories_bloc.dart';

enum AdminCategoriesStatus { initial, loading, loaded, failure }

class AdminCategoriesState extends Equatable {
  final AdminCategoriesStatus status;
  final List<AdminCategory> categories;
  final bool busy;
  final String? message;

  const AdminCategoriesState({
    this.status = AdminCategoriesStatus.initial,
    this.categories = const [],
    this.busy = false,
    this.message,
  });

  AdminCategoriesState copyWith({
    AdminCategoriesStatus? status,
    List<AdminCategory>? categories,
    bool? busy,
    String? message,
    bool clearMessage = false,
  }) =>
      AdminCategoriesState(
        status: status ?? this.status,
        categories: categories ?? this.categories,
        busy: busy ?? this.busy,
        message: clearMessage ? null : (message ?? this.message),
      );

  @override
  List<Object?> get props => [status, categories, busy, message];
}
