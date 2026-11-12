import 'package:flutter/material.dart';
import 'package:motorent/features/bidding_system/presentation/pages/bidding_home_page.dart';
import 'package:motorent/widgets/auth/auth_theme.dart';

/// الرئيسية للعميل: مشوار سريع ونقل بضائع.
class CustomerHomeSection extends StatelessWidget {
  const CustomerHomeSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AuthTheme.screenBackground(),
      child: const SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(20, 16, 20, 110),
        child: BiddingHomePage(embedInParent: true),
      ),
    );
  }
}
