import 'package:motorent/features/notifications/core/error/failures.dart';
import 'package:motorent/features/notifications/core/utils/either.dart';
import 'package:motorent/features/notifications/domain/repositories/notification_repository.dart';

class MarkAllNotificationsAsRead {
  final NotificationRepository repository;

  const MarkAllNotificationsAsRead(this.repository);

  Future<Either<Failure, Unit>> call() {
    return repository.markAllAsRead();
  }
}
