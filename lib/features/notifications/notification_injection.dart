import 'package:motorent/features/notifications/data/datasources/notification_local_data_source.dart';
import 'package:motorent/features/notifications/data/datasources/notification_remote_data_source.dart';
import 'package:motorent/features/notifications/data/repositories/notification_repository_impl.dart';
import 'package:motorent/features/notifications/domain/repositories/notification_repository.dart';
import 'package:motorent/features/notifications/domain/usecases/get_notifications.dart';
import 'package:motorent/features/notifications/domain/usecases/mark_all_notifications_as_read.dart';
import 'package:motorent/features/notifications/domain/usecases/mark_notification_as_read.dart';
import 'package:motorent/features/notifications/presentation/bloc/notification_bloc.dart';

class NotificationInjection {
  NotificationInjection._();

  static NotificationRepository createRepository() {
    return NotificationRepositoryImpl(
      localDataSource: NotificationLocalDataSourceImpl(),
      remoteDataSource: NotificationRemoteDataSourceImpl(),
    );
  }

  static NotificationBloc createBloc() {
    final repository = createRepository();
    return NotificationBloc(
      getNotifications: GetNotifications(repository),
      markNotificationAsRead: MarkNotificationAsRead(repository),
      markAllNotificationsAsRead: MarkAllNotificationsAsRead(repository),
    );
  }
}
