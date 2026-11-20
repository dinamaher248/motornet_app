import 'package:flutter/material.dart';
import 'package:motorent/widgets/auth/auth_theme.dart';

class NotificationKind {
  static const general = 'general';
  static const appUpdate = 'app_update';
  static const adminAlert = 'admin_alert';
  static const tripOffer = 'trip_offer';
  static const tripAccepted = 'trip_accepted';
  static const tripCancelled = 'trip_cancelled';
  static const newTrip = 'new_trip';
  static const biddingTrip = 'bidding_trip';
  static const offerAccepted = 'offer_accepted';
  static const tripCompleted = 'trip_completed';
  static const tripStatus = 'trip_status';
  static const bookingAccepted = 'booking_accepted';
  static const newServiceOrder = 'new_service_order';
  static const serviceOrderSent = 'service_order_sent';
  static const serviceOrderStatus = 'service_order_status';
  static const serviceOrderAccepted = 'service_order_accepted';
  static const serviceOrderRejected = 'service_order_rejected';
  static const serviceDriverAssigned = 'service_driver_assigned';
  static const customOrderOffer = 'custom_order_offer';
  static const customOfferAccepted = 'custom_offer_accepted';
  static const customOfferRejected = 'custom_offer_rejected';
  static const chat = 'chat';

  static String normalize(String? action) {
    final value = (action ?? '').trim().toLowerCase();
    if (value.isEmpty || value == 'open') return general;
    if (value == 'bidding_offer' || value == 'price_offer') return tripOffer;
    return value;
  }

  static String label(String? action) {
    switch (normalize(action)) {
      case appUpdate:
        return 'تحديث جديد للتطبيق';
      case adminAlert:
        return 'تنبيه من الإدارة';
      case newServiceOrder:
        return 'طلب جديد';
      case serviceOrderSent:
        return 'تم إرسال الطلب';
      case 'service_order_ready':
        return 'طلبك جاهز';
      case serviceOrderStatus:
      case serviceDriverAssigned:
        return 'تحديث في حالة الطلب';
      case serviceOrderAccepted:
        return 'قبول الطلب';
      case serviceOrderRejected:
        return 'رفض الطلب';
      case customOrderOffer:
        return 'عرض على طلبك';
      case customOfferAccepted:
        return 'قبول عرضك';
      case customOfferRejected:
        return 'رفض عرضك';
      case tripOffer:
        return 'عرض سعر';
      case tripAccepted:
        return 'قبول الطلب';
      case tripCancelled:
        return 'إلغاء الطلب';
      case newTrip:
        return 'طلب جديد';
      case biddingTrip:
        return 'طلب مزايدة جديد';
      case offerAccepted:
        return 'تم قبول عرضك';
      case tripCompleted:
        return 'تم تسليم الطلب';
      case tripStatus:
        return 'تحديث حالة الطلب';
      case bookingAccepted:
        return 'قبول الحجز';
      case chat:
        return 'رسالة محادثة';
      default:
        return 'رسالة عامة من صاحب التطبيق';
    }
  }

  static IconData icon(String? action) {
    switch (normalize(action)) {
      case appUpdate:
        return Icons.system_update_alt_rounded;
      case adminAlert:
        return Icons.admin_panel_settings_outlined;
      case newServiceOrder:
      case newTrip:
      case biddingTrip:
      case offerAccepted:
        return Icons.two_wheeler_outlined;
      case tripCompleted:
        return Icons.check_circle_outline_rounded;
      case tripStatus:
        return Icons.sync_alt_rounded;
      case serviceOrderSent:
        return Icons.send_rounded;
      case serviceOrderStatus:
      case serviceDriverAssigned:
        return Icons.sync_alt_rounded;
      case serviceOrderAccepted:
      case tripAccepted:
      case bookingAccepted:
        return Icons.check_circle_outline_rounded;
      case serviceOrderRejected:
      case tripCancelled:
        return Icons.cancel_outlined;
      case customOrderOffer:
        return Icons.local_offer_rounded;
      case customOfferAccepted:
        return Icons.check_circle_outline_rounded;
      case customOfferRejected:
        return Icons.cancel_outlined;
      case tripOffer:
        return Icons.local_offer_rounded;
      default:
        return Icons.campaign_outlined;
    }
  }

  static Color color(String? action) {
    switch (normalize(action)) {
      case appUpdate:
        return const Color(0xFF2563EB);
      case adminAlert:
        return const Color(0xFF9333EA);
      case newServiceOrder:
      case newTrip:
      case biddingTrip:
        return const Color(0xFF7C3AED);
      case serviceOrderSent:
        return const Color(0xFF0891B2);
      case serviceOrderStatus:
      case serviceDriverAssigned:
        return const Color(0xFF0D9488);
      case serviceOrderAccepted:
      case tripAccepted:
      case bookingAccepted:
        return const Color(0xFF059669);
      case serviceOrderRejected:
      case tripCancelled:
        return const Color(0xFFDC2626);
      case tripOffer:
        return AuthTheme.primary;
      case offerAccepted:
      case customOfferAccepted:
      case tripCompleted:
      case tripStatus:
        return const Color(0xFF059669);
      default:
        return AuthTheme.primaryDark;
    }
  }

  /// Merchant notification filter key for UI chips.
  static String? merchantFilterKey(String? action) {
    switch (normalize(action)) {
      case newServiceOrder:
        return 'new_order';
      case serviceOrderSent:
        return 'sent';
      case adminAlert:
        return 'admin';
      case serviceOrderStatus:
      case serviceDriverAssigned:
      case serviceOrderAccepted:
      case serviceOrderRejected:
      case customOfferAccepted:
      case customOfferRejected:
      case customOrderOffer:
        return 'status';
      case appUpdate:
        return 'update';
      case general:
        return 'general';
      default:
        return null;
    }
  }

  static bool isMerchantRelevant(String? action) {
    final key = merchantFilterKey(action);
    if (key != null) return true;
    return normalize(action) == general;
  }
}
