import 'package:motorent/features/notifications/core/error/failures.dart';
import 'package:motorent/features/notifications/core/utils/either.dart';
import 'package:motorent/features/notifications/domain/entities/app_notification.dart';
import 'package:motorent/features/notifications/domain/repositories/notification_repository.dart';

class GetNotifications {
  final NotificationRepository repository;

  const GetNotifications(this.repository);

  Future<Either<Failure, NotificationsPageResult>> call() {
    return repository.getNotifications();
  }
}
