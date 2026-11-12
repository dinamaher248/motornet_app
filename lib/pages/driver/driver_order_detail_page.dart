import 'package:flutter/material.dart';
import 'package:motorent/models/driver_models.dart';
import 'package:motorent/pages/order_tracking/active_order_tracking_page.dart';
import 'package:motorent/services/driver_api.dart';
import 'package:motorent/services/local_service_api.dart';
import 'package:motorent/services/trip_request_service.dart';
import 'package:motorent/widgets/auth/auth_theme.dart';
import 'package:motorent/widgets/rating_stars.dart';

class DriverOrderDetailPage extends StatefulWidget {
  final DriverOrderItem order;

  const DriverOrderDetailPage({super.key, required this.order});

  @override
  State<DriverOrderDetailPage> createState() => _DriverOrderDetailPageState();
}

class _DriverOrderDetailPageState extends State<DriverOrderDetailPage> {
  final _driverApi = DriverApi();
  final _tripService = TripRequestService();
  final _localService = LocalServiceApi();
  bool _isSubmitting = false;

  DriverOrderItem get order => widget.order;

  Future<void> _submitOffer() async {
    final controller = TextEditingController();
    final amount = await showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('عرض سعر'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'السعر (ج.م)'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () {
              final v = double.tryParse(controller.text.trim());
              if (v != null && v > 0) Navigator.pop(context, v);
            },
            child: const Text('إرسال'),
          ),
        ],
      ),
    );
    if (amount == null) return;

    setState(() => _isSubmitting = true);
    try {
      if (order.type == 'trip_request') {
        await _tripService.submitOffer(tripId: order.id, amount: amount);
      } else if (order.type == 'service_order') {
        await _localService.submitDeliveryOffer(order.id, amount);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('تم إرسال العرض — بانتظار قبول العميل/المتجر')),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _acceptInvitation() async {
    setState(() => _isSubmitting = true);
    try {
      await _driverApi.acceptServiceInvitation(order.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم قبول طلب التوصيل')),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ActiveOrderTrackingPage(
            type: 'service_order',
            id: order.id,
            isDriverView: true,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _openTracking() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ActiveOrderTrackingPage(
          type: order.type,
          id: order.id,
          isDriverView: true,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('تفاصيل الطلب')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(order.title,
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          _row('مكان الاستلام', order.pickLoc ?? '-'),
          _row('مكان التوصيل', order.targetLoc ?? '-'),
          if (order.distanceLabel != null)
            _row('المسافة التقريبية', order.distanceLabel!),
          _row('وصف الطلب', order.description ?? '-'),
          if (order.paymentMethodLabel != null)
            _row('طريقة الدفع', order.paymentMethodLabel!),
          if (order.myOfferAmount != null)
            _row('عرضك', '${order.myOfferAmount} ج.م'),
          if (order.offerStatus != null) _row('حالة العرض', order.offerStatus!),
          if (order.orderTotal != null)
            _row('قيمة الطلب', '${order.orderTotal} ج.م'),
          const SizedBox(height: 20),
          if (order.canAcceptInvitation)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: _isSubmitting ? null : _acceptInvitation,
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('قبول طلب التوصيل'),
              ),
            ),
          if (order.canOffer) ...[
            if (order.customerName != null) ...[
              const SizedBox(height: 8),
              Text(
                'العميل: ${order.customerName}',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              RatingStars(
                rating: order.customerRating,
                count: order.customerRatingsCount,
              ),
              const SizedBox(height: 12),
            ],
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AuthTheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: _isSubmitting ? null : _submitOffer,
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('عرض سعر'),
              ),
            ),
          ],
          if (order.showContact ||
              order.status == 'handed_to_driver' ||
              order.status == 'in_progress' ||
              order.status == 'driver_assigned') ...[
            const SizedBox(height: 12),
            if (order.customerName != null) ...[
              Text(
                'العميل: ${order.customerName}',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              RatingStars(
                rating: order.customerRating,
                count: order.customerRatingsCount,
              ),
              const SizedBox(height: 12),
            ],
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _openTracking,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AuthTheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                icon: const Icon(Icons.map_outlined),
                label: const Text('متابعة التنفيذ / التسليم'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(fontSize: 12, color: AuthTheme.textMuted)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
