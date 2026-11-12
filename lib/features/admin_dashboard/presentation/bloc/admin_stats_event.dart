part of 'admin_stats_bloc.dart';

abstract class AdminStatsEvent extends Equatable {
  const AdminStatsEvent();
  @override
  List<Object?> get props => [];
}

class FetchAdminStatsEvent extends AdminStatsEvent {
  const FetchAdminStatsEvent();
}
