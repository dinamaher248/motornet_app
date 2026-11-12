import 'package:flutter/material.dart';
import 'package:motorent/pages/customer/trip_request_form_page.dart';
import 'package:motorent/widgets/auth/auth_theme.dart';

class GoodsVehicleSelectPage extends StatelessWidget {
  const GoodsVehicleSelectPage({super.key});

  static const _options = [
    _VehicleOption(
      key: 'tricycle',
      title: 'تروسيكل',
      icon: Icons.electric_rickshaw,
    ),
    _VehicleOption(
      key: 'quarter_truck',
      title: 'ربع نقل',
      icon: Icons.local_shipping_outlined,
    ),
    _VehicleOption(
      key: 'half_truck',
      title: 'نصف نقل',
      icon: Icons.fire_truck_outlined,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('اختر وسيلة النقل'),
        centerTitle: true,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: _options.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final option = _options[index];
          return Card(
            elevation: 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 10,
              ),
              leading: CircleAvatar(
                backgroundColor: AuthTheme.primary.withOpacity(0.12),
                child: Icon(option.icon, color: AuthTheme.primary),
              ),
              title: Text(
                option.title,
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.w700,
                ),
              ),
              trailing: const Icon(Icons.arrow_back_ios_new, size: 16),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => TripRequestFormPage(
                      serviceType: 'goods',
                      vehicleType: option.key,
                      title: 'نقل بضائع - ${option.title}',
                      descriptionLabel: 'وصف البضاعة (إجباري)',
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _VehicleOption {
  final String key;
  final String title;
  final IconData icon;

  const _VehicleOption({
    required this.key,
    required this.title,
    required this.icon,
  });
}
