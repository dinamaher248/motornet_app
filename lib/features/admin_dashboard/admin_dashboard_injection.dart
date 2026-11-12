import 'package:motorent/features/admin_dashboard/data/datasources/admin_remote_data_source.dart';
import 'package:motorent/features/admin_dashboard/data/repositories/admin_repository_impl.dart';
import 'package:motorent/features/admin_dashboard/domain/repositories/admin_repository.dart';
import 'package:motorent/features/admin_dashboard/presentation/bloc/admin_categories_bloc.dart';
import 'package:motorent/features/admin_dashboard/presentation/bloc/admin_commissions_bloc.dart';
import 'package:motorent/features/admin_dashboard/presentation/bloc/admin_documents_bloc.dart';
import 'package:motorent/features/admin_dashboard/presentation/bloc/admin_moderators_bloc.dart';
import 'package:motorent/features/admin_dashboard/presentation/bloc/admin_notifications_bloc.dart';
import 'package:motorent/features/admin_dashboard/presentation/bloc/admin_payment_bloc.dart';
import 'package:motorent/features/admin_dashboard/presentation/bloc/admin_plans_bloc.dart';
import 'package:motorent/features/admin_dashboard/presentation/bloc/admin_products_bloc.dart';
import 'package:motorent/features/admin_dashboard/presentation/bloc/admin_stats_bloc.dart';
import 'package:motorent/features/admin_dashboard/presentation/bloc/admin_users_bloc.dart';

class AdminDashboardInjection {
  AdminDashboardInjection._();

  static AdminRepository createRepository() {
    return AdminRepositoryImpl(
      remoteDataSource: AdminRemoteDataSourceImpl(),
    );
  }

  static AdminStatsBloc createStatsBloc() =>
      AdminStatsBloc(repository: createRepository());

  static AdminUsersBloc createUsersBloc() =>
      AdminUsersBloc(repository: createRepository());

  static AdminCategoriesBloc createCategoriesBloc() =>
      AdminCategoriesBloc(repository: createRepository());

  static AdminProductsBloc createProductsBloc() =>
      AdminProductsBloc(repository: createRepository());

  static AdminCommissionsBloc createCommissionsBloc() =>
      AdminCommissionsBloc(repository: createRepository());

  static AdminPaymentBloc createPaymentBloc() =>
      AdminPaymentBloc(repository: createRepository());

  static AdminNotificationsBloc createNotificationsBloc() =>
      AdminNotificationsBloc(repository: createRepository());

  static AdminModeratorsBloc createModeratorsBloc() =>
      AdminModeratorsBloc(repository: createRepository());

  static AdminDocumentsBloc createDocumentsBloc() =>
      AdminDocumentsBloc(repository: createRepository());

  static AdminPlansBloc createPlansBloc() =>
      AdminPlansBloc(repository: createRepository());
}
