import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:motorent/features/admin_dashboard/domain/entities/admin_entities.dart';
import 'package:motorent/features/admin_dashboard/domain/repositories/admin_repository.dart';

part 'admin_stats_event.dart';
part 'admin_stats_state.dart';

class AdminStatsBloc extends Bloc<AdminStatsEvent, AdminStatsState> {
  final AdminRepository repository;

  AdminStatsBloc({required this.repository}) : super(const AdminStatsState()) {
    on<FetchAdminStatsEvent>(_onFetch);
  }

  Future<void> _onFetch(
    FetchAdminStatsEvent event,
    Emitter<AdminStatsState> emit,
  ) async {
    emit(state.copyWith(status: AdminStatsStatus.loading, clearMessage: true));
    final result = await repository.fetchStats();
    result.fold(
      (f) => emit(state.copyWith(
        status: AdminStatsStatus.failure,
        message: f.message,
      )),
      (stats) => emit(state.copyWith(
        status: AdminStatsStatus.loaded,
        stats: stats,
      )),
    );
  }
}
