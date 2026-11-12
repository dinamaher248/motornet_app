import 'package:flutter/material.dart';
import 'package:motorent/features/notifications/presentation/pages/notifications_screen.dart';

/// App shell entry — delegates to the notifications feature screen.
class NotificationsPage extends StatelessWidget {
  final int refreshToken;
  final bool isMerchant;

  const NotificationsPage({
    super.key,
    this.refreshToken = 0,
    this.isMerchant = false,
  });

  @override
  Widget build(BuildContext context) {
    return NotificationsScreen(
      refreshToken: refreshToken,
      showAppBar: true,
    );
  }
}
