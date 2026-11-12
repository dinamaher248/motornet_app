import 'package:motorent/features/notifications/core/error/failures.dart';
import 'package:motorent/features/notifications/core/utils/either.dart';
import 'package:motorent/features/notifications/domain/entities/app_notification.dart';

abstract class NotificationRepository {
  Future<Either<Failure, NotificationsPageResult>> getNotifications();

  Future<Either<Failure, Unit>> markAsRead(int id);

  Future<Either<Failure, Unit>> markAllAsRead();
}

/// Void success marker for Either.
class Unit {
  const Unit();
}

const unit = Unit();
