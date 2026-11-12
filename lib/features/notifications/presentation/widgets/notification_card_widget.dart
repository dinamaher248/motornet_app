import 'package:flutter/material.dart';
import 'package:motorent/features/notifications/core/utils/time_ago.dart';
import 'package:motorent/features/notifications/domain/entities/app_notification.dart';
import 'package:motorent/widgets/auth/auth_theme.dart';

class NotificationCardWidget extends StatelessWidget {
  final AppNotification notification;
  final VoidCallback onTap;

  const NotificationCardWidget({
    super.key,
    required this.notification,
    required this.onTap,
  });

  IconData get _icon {
    switch (notification.type.toLowerCase()) {
      case 'order_accepted':
      case 'order':
      case 'new_order':
      case 'new_trip':
      case 'bidding_trip':
        return Icons.two_wheeler_outlined;
      case 'system_update':
      case 'update':
      case 'app_update':
        return Icons.campaign_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  Color get _iconColor {
    switch (notification.type.toLowerCase()) {
      case 'order_accepted':
      case 'order':
      case 'new_order':
        return const Color(0xFF0C9F6A);
      case 'new_trip':
      case 'bidding_trip':
        return AuthTheme.primary;
      case 'system_update':
      case 'update':
      case 'app_update':
        return const Color(0xFF2563EB);
      default:
        return AuthTheme.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final unread = !notification.isRead;

    return Material(
      color: unread ? const Color(0xFFEFF6FF) : Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: unread
                  ? const Color(0xFFBFDBFE)
                  : AuthTheme.fieldBorder,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(_icon, color: _iconColor, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontWeight:
                                  unread ? FontWeight.w800 : FontWeight.w700,
                              fontSize: 15,
                              color: AuthTheme.textDark,
                            ),
                          ),
                        ),
                        if (unread)
                          Container(
                            width: 9,
                            height: 9,
                            margin: const EdgeInsets.only(right: 6),
                            decoration: const BoxDecoration(
                              color: Color(0xFF2563EB),
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    if (notification.body.trim().isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        notification.body,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 13,
                          height: 1.4,
                          color: AuthTheme.textMuted,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Text(
                      formatTimeAgoAr(notification.createdAt),
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 11,
                        color: AuthTheme.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
