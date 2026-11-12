import 'package:flutter/material.dart';
import 'package:motorent/features/bidding_system/presentation/pages/dynamic_vehicle_select_page.dart';

/// Kept for compatibility — redirects to the dynamic API-backed selector.
class GoodsVehicleSelectPage extends StatelessWidget {
  const GoodsVehicleSelectPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const DynamicVehicleSelectPage(
      category: 'goods',
      pageTitle: 'اختر نوع المركبة',
      serviceTitle: 'نقل بضائع',
      descriptionLabel: 'وصف البضاعة',
      accentColor: Color(0xFF0C9F6A),
    );
  }
}
