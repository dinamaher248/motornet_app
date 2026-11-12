import 'package:motorent/features/notifications/core/error/failures.dart';
import 'package:motorent/features/notifications/core/utils/either.dart';
import 'package:motorent/features/notifications/domain/repositories/notification_repository.dart';

class MarkNotificationAsRead {
  final NotificationRepository repository;

  const MarkNotificationAsRead(this.repository);

  Future<Either<Failure, Unit>> call(int id) {
    return repository.markAsRead(id);
  }
}
