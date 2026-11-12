import 'package:motorent/features/vendor_interface/domain/entities/vendor_entities.dart';

/// Pre-filled transport request when a vendor requests delivery for an order.
class VendorOrderDispatchPrefill {
  final int orderId;
  final String orderType;
  final String dropoffAddress;
  final double? dropoffLat;
  final double? dropoffLng;
  final String pickupAddress;
  final double? pickupLat;
  final double? pickupLng;
  final String? customerPhone;
  final String orderDescription;

  const VendorOrderDispatchPrefill({
    required this.orderId,
    required this.orderType,
    required this.dropoffAddress,
    this.dropoffLat,
    this.dropoffLng,
    required this.pickupAddress,
    this.pickupLat,
    this.pickupLng,
    this.customerPhone,
    required this.orderDescription,
  });

  String get linkNotes =>
      orderType == 'custom' ? 'custom_order:$orderId' : 'service_order:$orderId';

  bool get hasDropoffPoint =>
      dropoffLat != null &&
      dropoffLng != null &&
      dropoffLat!.abs() > 0.0001 &&
      dropoffLng!.abs() > 0.0001;

  bool get hasPickupPoint =>
      pickupLat != null &&
      pickupLng != null &&
      pickupLat!.abs() > 0.0001 &&
      pickupLng!.abs() > 0.0001;

  static String formatDeliveryAddress(String raw) {
    final text = raw.trim();
    if (text.isEmpty) return '';
    if (text.contains(' — ')) {
      final detail = text.split(' — ').last.trim();
      if (detail.isNotEmpty && !detail.contains('موقعي الحالي')) {
        return detail;
      }
    }
    final cleaned = text
        .replaceAll(RegExp(r'موقعي الحالي\s*\([^)]+\)\s*-?\s*'), '')
        .trim();
    return cleaned.isEmpty ? text : cleaned;
  }

  factory VendorOrderDispatchPrefill.fromOrder(VendorOrder order) {
    final dropoff = formatDeliveryAddress(order.deliveryAddress);
    final pickup = (order.storeAddress ?? '').trim().isNotEmpty
        ? order.storeAddress!.trim()
        : 'موقع النشاط';
    final title = order.isCustom ? 'طلب مخصص' : order.productName;
    return VendorOrderDispatchPrefill(
      orderId: order.id,
      orderType: order.orderType,
      dropoffAddress: dropoff.isNotEmpty ? dropoff : order.deliveryAddress,
      dropoffLat: order.deliveryLat,
      dropoffLng: order.deliveryLng,
      pickupAddress: pickup,
      pickupLat: order.storeLat,
      pickupLng: order.storeLng,
      customerPhone: order.customerPhone,
      orderDescription: 'توصيل طلب #${order.id} — $title',
    );
  }
}
