import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:motorent/features/notifications/domain/entities/app_notification.dart';
import 'package:motorent/features/notifications/domain/usecases/get_notifications.dart';
import 'package:motorent/features/notifications/domain/usecases/mark_all_notifications_as_read.dart';
import 'package:motorent/features/notifications/domain/usecases/mark_notification_as_read.dart';

part 'notification_event.dart';
part 'notification_state.dart';

class NotificationBloc extends Bloc<NotificationEvent, NotificationState> {
  final GetNotifications getNotifications;
  final MarkNotificationAsRead markNotificationAsRead;
  final MarkAllNotificationsAsRead markAllNotificationsAsRead;

  NotificationBloc({
    required this.getNotifications,
    required this.markNotificationAsRead,
    required this.markAllNotificationsAsRead,
  }) : super(const NotificationInitial()) {
    on<FetchNotificationsEvent>(_onFetch);
    on<MarkAsReadEvent>(_onMarkAsRead);
    on<MarkAllAsReadEvent>(_onMarkAllAsRead);
  }

  Future<void> _onFetch(
    FetchNotificationsEvent event,
    Emitter<NotificationState> emit,
  ) async {
    final previous = state;
    if (previous is! NotificationsLoadedSuccess) {
      emit(const NotificationLoading());
    }

    final result = await getNotifications();
    result.fold(
      (failure) {
        if (previous is NotificationsLoadedSuccess) {
          emit(previous);
          return;
        }
        emit(NotificationError(failure.message));
      },
      (page) => emit(NotificationsLoadedSuccess(
        notifications: page.notifications,
        unreadCount: page.unreadCount,
      )),
    );
  }

  Future<void> _onMarkAsRead(
    MarkAsReadEvent event,
    Emitter<NotificationState> emit,
  ) async {
    final current = state;
    if (current is! NotificationsLoadedSuccess) return;

    final index = current.notifications.indexWhere((n) => n.id == event.id);
    if (index < 0) return;

    final target = current.notifications[index];
    if (target.isRead) return;

    // Optimistic UI update
    final updated = List<AppNotification>.from(current.notifications);
    updated[index] = target.copyWith(isRead: true);
    final unread = (current.unreadCount - 1).clamp(0, updated.length);
    emit(NotificationsLoadedSuccess(
      notifications: updated,
      unreadCount: unread,
    ));

    final result = await markNotificationAsRead(event.id);
    result.fold(
      (failure) {
        // Revert on failure
        emit(current);
        emit(NotificationError(failure.message));
        emit(current);
      },
      (_) {},
    );
  }

  Future<void> _onMarkAllAsRead(
    MarkAllAsReadEvent event,
    Emitter<NotificationState> emit,
  ) async {
    final current = state;
    if (current is! NotificationsLoadedSuccess) return;
    if (current.unreadCount == 0) return;

    final previous = current;
    final updated = current.notifications
        .map((n) => n.isRead ? n : n.copyWith(isRead: true))
        .toList();

    emit(NotificationsLoadedSuccess(
      notifications: updated,
      unreadCount: 0,
    ));

    final result = await markAllNotificationsAsRead();
    result.fold(
      (failure) {
        emit(previous);
        emit(NotificationError(failure.message));
        emit(previous);
      },
      (_) {},
    );
  }
}
