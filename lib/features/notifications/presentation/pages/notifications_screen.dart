import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:motorent/data/local/dbTablesHelpers/dbModels/db_models.dart';
import 'package:motorent/features/notifications/domain/entities/app_notification.dart';
import 'package:motorent/features/notifications/notification_injection.dart';
import 'package:motorent/features/notifications/presentation/bloc/notification_bloc.dart';
import 'package:motorent/features/notifications/presentation/widgets/notification_card_widget.dart';
import 'package:motorent/services/notification_navigator.dart';
import 'package:motorent/services/notification_store.dart';
import 'package:motorent/widgets/auth/auth_theme.dart';

class NotificationsScreen extends StatelessWidget {
  final int refreshToken;
  final bool showAppBar;

  const NotificationsScreen({
    super.key,
    this.refreshToken = 0,
    this.showAppBar = true,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          NotificationInjection.createBloc()..add(const FetchNotificationsEvent()),
      child: _NotificationsView(
        refreshToken: refreshToken,
        showAppBar: showAppBar,
      ),
    );
  }
}

class _NotificationsView extends StatefulWidget {
  final int refreshToken;
  final bool showAppBar;

  const _NotificationsView({
    required this.refreshToken,
    required this.showAppBar,
  });

  @override
  State<_NotificationsView> createState() => _NotificationsViewState();
}

class _NotificationsViewState extends State<_NotificationsView> {
  StreamSubscription<void>? _storeSub;
  Timer? _refreshDebounce;

  @override
  void initState() {
    super.initState();
    _storeSub = NotificationStore.instance.changes.listen((_) {
      _refreshDebounce?.cancel();
      _refreshDebounce = Timer(const Duration(milliseconds: 400), () {
        if (!mounted) return;
        context.read<NotificationBloc>().add(const FetchNotificationsEvent());
      });
    });
  }

  @override
  void dispose() {
    _refreshDebounce?.cancel();
    _storeSub?.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant _NotificationsView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.refreshToken != oldWidget.refreshToken) {
      context.read<NotificationBloc>().add(const FetchNotificationsEvent());
    }
  }

  Future<void> _openItem(AppNotification item) async {
    if (!item.isRead) {
      context.read<NotificationBloc>().add(MarkAsReadEvent(item.id));
    }

    await NotificationNavigator.open(
      context,
      NotificationItem(
        id: item.id,
        title: item.title,
        description: item.body,
        action: item.action ?? item.type,
        topic: 'motorent',
        refId: item.refId,
        createdAt: item.createdAt?.toIso8601String(),
        isRead: true,
      ),
    );

    if (mounted) {
      context.read<NotificationBloc>().add(const FetchNotificationsEvent());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: widget.showAppBar
          ? AppBar(
              automaticallyImplyLeading: false,
              title: const Text(
                'الإشعارات',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.w700,
                ),
              ),
              centerTitle: true,
              actions: [
                BlocBuilder<NotificationBloc, NotificationState>(
                  builder: (context, state) {
                    final hasUnread = state is NotificationsLoadedSuccess &&
                        state.hasUnread;
                    if (!hasUnread) return const SizedBox.shrink();

                    return TextButton(
                      onPressed: () {
                        context
                            .read<NotificationBloc>()
                            .add(const MarkAllAsReadEvent());
                      },
                      child: const Text(
                        'تحديد الكل كمقروء',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    );
                  },
                ),
              ],
            )
          : null,
      body: Container(
        decoration: AuthTheme.screenBackground(),
        child: BlocBuilder<NotificationBloc, NotificationState>(
          builder: (context, state) {
            if (state is NotificationLoading || state is NotificationInitial) {
              return const Center(child: CircularProgressIndicator());
            }

            final notifications = state is NotificationsLoadedSuccess
                ? state.notifications
                : const <AppNotification>[];
            final errorText =
                state is NotificationError ? state.message : null;

            return RefreshIndicator(
              onRefresh: () async {
                context
                    .read<NotificationBloc>()
                    .add(const FetchNotificationsEvent());
                await Future<void>.delayed(const Duration(milliseconds: 250));
              },
              child: notifications.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.25,
                        ),
                        Icon(
                          Icons.notifications_none_rounded,
                          size: 72,
                          color: AuthTheme.primary.withValues(alpha: 0.45),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          errorText != null && errorText.trim().isNotEmpty
                              ? 'تعذر تحميل الإشعارات\n$errorText'
                              : 'لا توجد إشعارات حالياً',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AuthTheme.textMuted,
                            height: 1.4,
                          ),
                        ),
                      ],
                    )
                  : ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                      itemCount: notifications.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final item = notifications[index];
                        return NotificationCardWidget(
                          notification: item,
                          onTap: () => _openItem(item),
                        );
                      },
                    ),
            );
          },
        ),
      ),
    );
  }
}
