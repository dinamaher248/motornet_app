import 'package:motorent/features/notifications/core/error/exceptions.dart';
import 'package:motorent/features/notifications/core/error/failures.dart';
import 'package:motorent/features/notifications/core/utils/either.dart';
import 'package:motorent/features/notifications/data/datasources/notification_local_data_source.dart';
import 'package:motorent/features/notifications/data/datasources/notification_remote_data_source.dart';
import 'package:motorent/features/notifications/domain/entities/app_notification.dart';
import 'package:motorent/features/notifications/domain/repositories/notification_repository.dart';
import 'package:motorent/services/notification_store.dart';

/// Server inbox is the source of truth for in-app list + badge.
/// Local SQLite keeps a cache (incl. FCM) and is used offline.
class NotificationRepositoryImpl implements NotificationRepository {
  final NotificationLocalDataSource localDataSource;
  final NotificationRemoteDataSource? remoteDataSource;

  const NotificationRepositoryImpl({
    required this.localDataSource,
    this.remoteDataSource,
  });

  @override
  Future<Either<Failure, NotificationsPageResult>> getNotifications() async {
    try {
      if (remoteDataSource != null) {
        try {
          final remote = await remoteDataSource!.getNotifications();
          // Cache into local without firing change listeners during fetch
          // (avoids infinite refresh loops in the notifications screen).
          await NotificationStore.instance.syncFromServer(
            remote.notifications,
            notify: false,
          );
          return Right(remote);
        } catch (_) {
          // Fall through to local cache.
        }
      }

      final local = await localDataSource.getNotifications();
      return Right(local);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, statusCode: e.statusCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(UnexpectedFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> markAsRead(int id) async {
    try {
      var synced = false;
      if (remoteDataSource != null) {
        try {
          await remoteDataSource!.markAsRead(id);
          synced = true;
        } catch (_) {}
      }
      try {
        await NotificationStore.instance.markServerAsRead(id);
        synced = true;
      } catch (_) {}
      try {
        await localDataSource.markAsRead(id);
        synced = true;
      } catch (_) {}
      NotificationStore.instance.notifyChanged();
      if (!synced) {
        return const Left(UnexpectedFailure('تعذر تحديث الإشعار'));
      }
      return const Right(unit);
    } catch (e) {
      return Left(UnexpectedFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> markAllAsRead() async {
    try {
      var synced = false;
      if (remoteDataSource != null) {
        try {
          await remoteDataSource!.markAllAsRead();
          synced = true;
        } catch (_) {}
      }
      try {
        await localDataSource.markAllAsRead();
        synced = true;
      } catch (_) {}
      NotificationStore.instance.notifyChanged();
      if (!synced) {
        return const Left(UnexpectedFailure('تعذر تحديث الإشعارات'));
      }
      return const Right(unit);
    } catch (e) {
      return Left(UnexpectedFailure(e.toString()));
    }
  }
}
