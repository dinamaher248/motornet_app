import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:motorent/data/local/cache_helper.dart';
import 'package:motorent/data/local/dbTablesHelpers/dbModels/db_models.dart';
import 'package:motorent/features/bidding_system/presentation/pages/trip_details_screen.dart';
import 'package:motorent/features/driver_interface/domain/entities/driver_entities.dart';
import 'package:motorent/features/driver_interface/driver_interface_injection.dart';
import 'package:motorent/features/driver_interface/presentation/pages/driver_trip_detail_screen.dart';
import 'package:motorent/features/services/domain/entities/service_entities.dart';
import 'package:motorent/features/services/presentation/pages/offer_received_dialog.dart';
import 'package:motorent/features/vendor_interface/presentation/pages/vendor_orders_screen.dart';
import 'package:motorent/features/vendor_interface/presentation/pages/vendor_reservations_screen.dart';
import 'package:motorent/features/services/presentation/pages/my_bookings_screen.dart';
import 'package:motorent/pages/merchant/merchant_order_detail_page.dart';
import 'package:motorent/pages/services/customer_service_order_detail_page.dart';
import 'package:motorent/pages/order_tracking/active_order_tracking_page.dart';
import 'package:motorent/pages/orders_tab_page.dart';
import 'package:motorent/pages/chat_utou_pageTwo.dart';
import 'package:motorent/services/local_service_api.dart';
import 'package:motorent/services/merchant_owner_api.dart';
import 'package:motorent/services/notification_store.dart';
import 'package:motorent/services/pending_rating_service.dart';
import 'package:motorent/utils/notification_kind.dart';
import 'package:motorent/widgets/auth/auth_theme.dart';
import 'package:url_launcher/url_launcher.dart';

class NotificationNavigator {
  static Future<void> open(
    BuildContext context,
    NotificationItem item, {
    bool showDetailsSheet = true,
  }) async {
    if (item.id != null) {
      await NotificationStore.instance.markAsRead(item.id!);
    }

    final action = NotificationKind.normalize(item.action);
    final handled = await _navigateByAction(context, action, item);

    if (!handled && showDetailsSheet) {
      _showDetailsSheet(context, item);
    }
  }

  static Future<void> openFromPayload(BuildContext context, String? payload) async {
    if (payload == null || payload.trim().isEmpty) return;

    try {
      final map = jsonDecode(payload) as Map<String, dynamic>;
      final item = NotificationItem(
        title: map['title']?.toString() ?? 'إشعار',
        description: map['body']?.toString() ?? '',
        action: map['action']?.toString() ?? '',
        topic: map['topic']?.toString() ?? 'motorent',
        refId: map['ref_id']?.toString(),
      );
      await open(context, item, showDetailsSheet: false);
    } catch (_) {
      final items = await NotificationStore.instance.getAll();
      if (items.isNotEmpty && context.mounted) {
        await open(context, items.first, showDetailsSheet: false);
      }
    }
  }

  static Future<bool> _navigateByAction(
    BuildContext context,
    String action,
    NotificationItem item,
  ) async {
    switch (action) {
      case NotificationKind.appUpdate:
        final url = (item.refId ?? '').trim();
        if (url.isNotEmpty) {
          final uri = Uri.tryParse(url);
          if (uri != null && await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
            return true;
          }
        }
        return false;

      case NotificationKind.tripOffer:
      case NotificationKind.tripCancelled:
      case NotificationKind.newTrip:
      case NotificationKind.biddingTrip:
        return _openTrip(context, item.refId);

      case NotificationKind.tripAccepted:
        return _openAcceptedTripTracking(context, item);

      case NotificationKind.offerAccepted:
      case NotificationKind.tripCompleted:
      case NotificationKind.tripStatus:
        final opened = await _openAcceptedTripTracking(context, item);
        if (action == NotificationKind.tripCompleted && context.mounted) {
          // فتح شاشة التقييم للعميل بعد التسليم
          await PendingRatingService.promptIfNeeded(context);
        }
        return opened;

      case NotificationKind.bookingAccepted:
        if (!context.mounted) return false;
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const OrdersPage()),
        );
        return true;

      case NotificationKind.customOrderOffer:
        return _openCustomOrderOffer(context, item.refId);

      case NotificationKind.customOfferAccepted:
      case NotificationKind.customOfferRejected:
      case NotificationKind.newServiceOrder:
      case NotificationKind.serviceOrderSent:
      case NotificationKind.serviceOrderStatus:
      case NotificationKind.serviceOrderAccepted:
      case NotificationKind.serviceOrderRejected:
      case NotificationKind.serviceDriverAssigned:
        return _openServiceOrderNotification(context, action, item.refId);

      // إشعارات الحجز: العميل ← «حجوزاتي»، صاحب النشاط ← «الحجوزات»
      case 'reservation_quoted':
      case 'reservation_unavailable':
      case 'reservation_cancelled':
      case 'reservation_rejected_by_owner':
        if (!context.mounted) return false;
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const MyBookingsScreen()),
        );
        return true;

      case 'new_reservation_booking':
      case 'reservation_confirmed':
      case 'reservation_rejected':
      case 'reservation_customer_cancelled':
        if (!context.mounted) return false;
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const VendorReservationsScreen(),
          ),
        );
        return true;

      case NotificationKind.adminAlert:
        return false;

      case NotificationKind.chat:
        return _openChatFromNotification(context, item);

      default:
        return false;
    }
  }

  static Future<bool> _openChatFromNotification(
    BuildContext context,
    NotificationItem item,
  ) async {
    final myId = CacheHelper.getData(key: 'id')?.toString() ?? '';
    if (myId.isEmpty) return false;

    final ref = (item.refId ?? '').trim();
    String? type;
    int? orderId;

    final named = RegExp(
      r'^(bidding_trip|service_order|custom_order)_(\d+)$',
    ).firstMatch(ref);
    if (named != null) {
      type = named.group(1);
      orderId = int.tryParse(named.group(2)!);
    } else {
      orderId = int.tryParse(ref);
      type = 'bidding_trip';
    }

    if (orderId != null && type != null) {
      final role = (CacheHelper.getData(key: 'title') ??
              CacheHelper.getData(key: 'role') ??
              '')
          .toString();
      if (!context.mounted) return true;
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ActiveOrderTrackingPage(
            type: type!,
            id: orderId!,
            isDriverView: role == 'driver',
          ),
        ),
      );
      return true;
    }

    if (ref.isNotEmpty && context.mounted) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatPage(
            roomId: ref.contains('_') ? ref : 'ride_$ref',
            partnerId: '0',
            currentUserId: myId,
          ),
        ),
      );
      return true;
    }
    return false;
  }

  static Future<bool> _openCustomOrderOffer(
    BuildContext context,
    String? refId,
  ) async {
    final orderId = int.tryParse(refId ?? '');
    if (orderId == null) return false;

    try {
      final order = await LocalServiceApi().fetchOrder(orderId);
      if (!context.mounted) return true;

      final custom = CustomOrder(
        id: order.id,
        orderType: order.orderType,
        storeId: order.merchantId,
        storeName: order.merchantName,
        requestText: order.customRequestText,
        requestImage: order.customRequestImage,
        deliveryAddress: order.deliveryAddress,
        contactPhone: order.customerContactPhone,
        notes: order.notes,
        offerPrice: order.merchantOfferPrice ?? order.totalPrice,
        offerNotes: order.merchantOfferNotes,
        status: order.status,
        statusLabel: order.statusLabel,
        canAcceptOffer: order.canAcceptOffer,
        canRejectOffer: order.canRejectOffer,
      );

      if (order.canAcceptOffer || order.canRejectOffer) {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => OfferReceivedScreen(order: custom),
          ),
        );
      } else {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CustomerServiceOrderDetailPage(order: order),
          ),
        );
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> _openServiceOrderNotification(
    BuildContext context,
    String action,
    String? refId,
  ) async {
    final title = (CacheHelper.getData(key: 'title') ??
            CacheHelper.getData(key: 'role') ??
            '')
        .toString()
        .toLowerCase();
    final isMerchant = title == 'merchant' || title == 'vendor';

    // إشعارات التاجر (طلب جديد / تحديث حالة من العميل)
    if (isMerchant ||
        action == NotificationKind.newServiceOrder ||
        action == NotificationKind.customOfferAccepted ||
        action == NotificationKind.customOfferRejected) {
      return _openMerchantOrder(context, refId);
    }

    // العميل: قبول/رفض/تحديث → تفاصيل الطلب لاختيار الاستلام
    final orderId = int.tryParse(refId ?? '');
    if (orderId == null) return false;
    try {
      final order = await LocalServiceApi().fetchOrder(orderId);
      if (!context.mounted) return true;
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CustomerServiceOrderDetailPage(order: order),
        ),
      );
      return true;
    } catch (_) {
      if (!context.mounted) return false;
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const OrdersPage()),
      );
      return true;
    }
  }

  static Future<bool> _openMerchantOrder(
    BuildContext context,
    String? refId,
  ) async {
    final title = CacheHelper.getData(key: 'title')?.toString() ?? '';
    if (title != 'merchant' && title != 'vendor') return false;

    final orderId = int.tryParse(refId ?? '');
    if (orderId == null) {
      if (!context.mounted) return false;
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const VendorOrdersScreen()),
      );
      return true;
    }

    try {
      final order = await MerchantOwnerApi().fetchOrder(orderId);
      if (!context.mounted) return true;
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => MerchantOrderDetailPage(order: order),
        ),
      );
      return true;
    } catch (_) {
      if (!context.mounted) return false;
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const VendorOrdersScreen()),
      );
      return true;
    }
  }

  static Future<bool> _openAcceptedTripTracking(
    BuildContext context,
    NotificationItem item,
  ) async {
    final tripId = int.tryParse(item.refId ?? '');
    if (tripId == null) {
      if (!context.mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذر فتح الطلب من هذا الإشعار')),
      );
      return false;
    }

    final role = (CacheHelper.getData(key: 'title') ??
            CacheHelper.getData(key: 'role') ??
            '')
        .toString();
    final isDriver = role == 'driver';

    if (!context.mounted) return false;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ActiveOrderTrackingPage(
          type: 'bidding_trip',
          id: tripId,
          isDriverView: isDriver,
        ),
      ),
    );
    return true;
  }

  static Future<bool> _openTrip(BuildContext context, String? refId) async {
    final tripId = int.tryParse(refId ?? '');
    if (tripId == null) {
      if (!context.mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذر فتح الطلب من هذا الإشعار')),
      );
      return false;
    }

    final role = (CacheHelper.getData(key: 'title') ??
            CacheHelper.getData(key: 'role') ??
            '')
        .toString();

    try {
      if (role == 'driver') {
        // طلب جديد للسائق → صفحة التفاصيل/عرض السعر من الطلبات المتاحة
        final bids = await DriverInterfaceInjection.createRepository()
            .fetchAvailableBids();
        DriverTrip? found;
        bids.fold((_) {}, (list) {
          for (final t in list) {
            if (t.id == tripId) found = t;
          }
        });
        if (!context.mounted) return true;
        if (found == null) {
          // غالباً اتقبل العرض وبقت الرحلة جارية — افتح المتابعة
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ActiveOrderTrackingPage(
                type: 'bidding_trip',
                id: tripId,
                isDriverView: true,
              ),
            ),
          );
          return true;
        }
        final trip = found!;
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => BlocProvider(
              create: (_) => DriverInterfaceInjection.createHomeBloc(),
              child: DriverTripDetailScreen(trip: trip),
            ),
          ),
        );
        return true;
      }

      // العميل → تفاصيل الطلب/العروض (نظام المزايدة الحالي)
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => TripDetailsScreen(tripId: tripId),
        ),
      );
      return true;
    } catch (_) {
      if (!context.mounted) return false;
      // محاولة أخيرة: متابعة التنفيذ إن كان الطلب جارياً
      try {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ActiveOrderTrackingPage(
              type: 'bidding_trip',
              id: tripId,
              isDriverView: role == 'driver',
            ),
          ),
        );
        return true;
      } catch (_) {
        if (!context.mounted) return false;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('الطلب غير موجود أو لم يعد متاحاً')),
        );
        return false;
      }
    }
  }

  /// رقم هاتف داخل نص الإشعار (يُستخدم لزر «اتصال» في إشعار الجاهزية).
  static String? _phoneIn(String text) {
    final m = RegExp(r'اتصال:\s*(\+?\d[\d\s-]{7,})').firstMatch(text);
    if (m == null) return null;
    final cleaned = m.group(1)!.replaceAll(RegExp(r'[^\d+]'), '');
    return cleaned.length >= 8 ? cleaned : null;
  }

  static void _showDetailsSheet(BuildContext context, NotificationItem item) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        final kindColor = NotificationKind.color(item.action);
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: kindColor.withOpacity(0.12),
                      child: Icon(
                        NotificationKind.icon(item.action),
                        color: kindColor,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            NotificationKind.label(item.action),
                            style: TextStyle(
                              fontSize: 12,
                              color: kindColor,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            item.title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  item.description,
                  style: const TextStyle(fontSize: 14, height: 1.4),
                ),
                if (item.createdAt != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    item.createdAt!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AuthTheme.textMuted,
                    ),
                  ),
                ],
                if (_phoneIn(item.description) != null) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => launchUrl(
                        Uri(scheme: 'tel', path: _phoneIn(item.description)),
                      ),
                      icon: const Icon(Icons.call),
                      label: const Text('اتصال'),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('إغلاق'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
