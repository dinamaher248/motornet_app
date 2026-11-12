import 'package:flutter/material.dart';
import 'package:motorent/features/bidding_system/presentation/pages/my_trips_screen.dart';

/// Legacy entry point — delegates to bidding_system MyTripsScreen.
class OrderTrackingPage extends StatelessWidget {
  const OrderTrackingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const MyTripsScreen(showAppBar: true);
  }
}
