import 'package:flutter/material.dart';
import 'package:motorent/models/trip_request_models.dart';
import 'package:motorent/services/trip_request_service.dart';
import 'package:motorent/widgets/auth/auth_theme.dart';

class DriverTripRequestsSection extends StatefulWidget {
  const DriverTripRequestsSection({super.key});

  @override
  State<DriverTripRequestsSection> createState() =>
      _DriverTripRequestsSectionState();
}

class _DriverTripRequestsSectionState extends State<DriverTripRequestsSection> {
  final _service = TripRequestService();
  List<TripRequestItem> _requests = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final items = await _service.fetchDriverRequests();
      if (!mounted) return;
      setState(() {
        _requests = items;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _showOfferDialog(TripRequestItem trip) async {
    final controller = TextEditingController();
    final amount = await showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تقديم عرض سعر'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'قيمة المشوار (ج.م)',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              final value = double.tryParse(controller.text.trim());
              if (value == null || value <= 0) return;
              Navigator.pop(context, value);
            },
            child: const Text('إرسال العرض'),
          ),
        ],
      ),
    );

    if (amount == null) return;

    try {
      await _service.submitOffer(tripId: trip.id, amount: amount);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم إرسال العرض بنجاح')),
      );
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }

    if (_requests.isEmpty) {
      return const Text(
        'لا توجد طلبات عملاء جديدة حالياً.',
        style: TextStyle(color: AuthTheme.textMuted),
      );
    }

    return Column(
      children: _requests.map((trip) {
        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  trip.vehicleTypeLabel,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AuthTheme.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Text('من: ${trip.pickLoc}'),
                Text('إلى: ${trip.targetLoc}'),
                if (trip.distanceKm != null)
                  Text('المسافة: ${trip.distanceKm} كم'),
                const SizedBox(height: 6),
                Text('الوصف: ${trip.description}'),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _showOfferDialog(trip),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AuthTheme.primary,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('تقديم عرض سعر'),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
