import 'package:flutter/material.dart';
import 'package:motorent/features/my_account/presentation/pages/profile_screen.dart';

/// App shell entry — delegates to the my_account feature.
class ProfilePage extends StatelessWidget {
  final int refreshToken;

  const ProfilePage({
    super.key,
    this.refreshToken = 0,
  });

  @override
  Widget build(BuildContext context) {
    return ProfileScreen(refreshToken: refreshToken);
  }
}
