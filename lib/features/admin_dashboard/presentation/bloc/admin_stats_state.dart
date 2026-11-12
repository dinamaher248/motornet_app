part of 'admin_stats_bloc.dart';

enum AdminStatsStatus { initial, loading, loaded, failure }

class AdminStatsState extends Equatable {
  final AdminStatsStatus status;
  final AdminStats stats;
  final String? message;

  const AdminStatsState({
    this.status = AdminStatsStatus.initial,
    this.stats = const AdminStats(),
    this.message,
  });

  AdminStatsState copyWith({
    AdminStatsStatus? status,
    AdminStats? stats,
    String? message,
    bool clearMessage = false,
  }) =>
      AdminStatsState(
        status: status ?? this.status,
        stats: stats ?? this.stats,
        message: clearMessage ? null : (message ?? this.message),
      );

  @override
  List<Object?> get props => [status, stats, message];
}
