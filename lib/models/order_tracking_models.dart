class OrderTrackingDriver {
  final int id;
  final String name;
  final String? image;
  final String? phone;
  final double rating;
  final int ratingsCount;
  final double? lat;
  final double? lng;

  OrderTrackingDriver({
    required this.id,
    required this.name,
    this.image,
    this.phone,
    this.rating = 0,
    this.ratingsCount = 0,
    this.lat,
    this.lng,
  });

  factory OrderTrackingDriver.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return OrderTrackingDriver(id: 0, name: 'سائق');
    }
    final rawPhone = (json['phone'] ?? json['mobile'] ?? json['contact_phone'])
        ?.toString()
        .trim();
    return OrderTrackingDriver(
      id: int.tryParse('${json['id'] ?? 0}') ?? 0,
      name: json['name']?.toString() ?? 'سائق',
      image: json['image']?.toString(),
      phone: (rawPhone == null || rawPhone.isEmpty || rawPhone == 'null')
          ? null
          : rawPhone,
      rating: double.tryParse(
            '${json['avg_rating'] ?? json['rating'] ?? 0}') ??
          0,
      ratingsCount: int.tryParse(
            '${json['ratings_count'] ?? json['ratingsCount'] ?? 0}') ??
          0,
      lat: double.tryParse(
          '${json['lat'] ?? json['last_lat'] ?? ''}'),
      lng: double.tryParse(
          '${json['lng'] ?? json['last_lng'] ?? ''}'),
    );
  }
}

bool _orderTrackingTruthy(dynamic v) {
  if (v == true || v == 1) return true;
  if (v is String) {
    final s = v.trim().toLowerCase();
    return s == '1' || s == 'true' || s == 'yes';
  }
  return false;
}

class OrderTrackingData {
  final String type;
  final int id;
  final String status;
  final String statusLabel;
  final double price;
  final String pickupAddress;
  final String dropoffAddress;
  final double? pickupLat;
  final double? pickupLng;
  final double? dropoffLat;
  final double? dropoffLng;
  final String? distanceDriverToPickupLabel;
  final String? routeDistanceLabel;
  final OrderTrackingDriver? driver;
  final OrderTrackingDriver? customer;
  /// رقم التواصل المكتوب في الطلب (يفضَّل على رقم الحساب).
  final String? contactPhone;
  final int? rideBookId;
  final int? partnerUserId;
  final String? chatRoomId;
  final bool canChat;
  final bool canCall;
  final bool canHandToDriver;
  final bool canEndOrder;
  final bool canConfirmDelivery;
  final bool canGoToPickup;
  final bool canMarkPickedUp;
  final bool handedToDriver;
  final bool isCompleted;
  final int? rateeUserId;
  final int? merchantId;
  final String? merchantName;
  final String? merchantImage;
  final String? merchantPhone;
  final double merchantRating;
  final int merchantRatingsCount;
  /// customer | driver | vendor | other
  final String viewerRole;

  OrderTrackingData({
    required this.type,
    required this.id,
    required this.status,
    required this.statusLabel,
    required this.price,
    required this.pickupAddress,
    required this.dropoffAddress,
    this.pickupLat,
    this.pickupLng,
    this.dropoffLat,
    this.dropoffLng,
    this.distanceDriverToPickupLabel,
    this.routeDistanceLabel,
    this.driver,
    this.customer,
    this.contactPhone,
    this.rideBookId,
    this.partnerUserId,
    this.chatRoomId,
    this.canChat = false,
    this.canCall = false,
    this.canHandToDriver = false,
    this.canEndOrder = false,
    this.canConfirmDelivery = false,
    this.canGoToPickup = false,
    this.canMarkPickedUp = false,
    this.handedToDriver = false,
    this.isCompleted = false,
    this.rateeUserId,
    this.merchantId,
    this.merchantName,
    this.merchantImage,
    this.merchantPhone,
    this.merchantRating = 0,
    this.merchantRatingsCount = 0,
    this.viewerRole = 'customer',
  });

  factory OrderTrackingData.fromJson(Map<String, dynamic> json) {
    return OrderTrackingData(
      type: json['type']?.toString() ?? '',
      id: int.tryParse('${json['id'] ?? 0}') ?? 0,
      status: json['status']?.toString() ?? '',
      statusLabel: json['status_label']?.toString() ?? '',
      price: double.tryParse('${json['price'] ?? 0}') ?? 0,
      pickupAddress: json['pickup_address']?.toString() ?? '',
      dropoffAddress: json['dropoff_address']?.toString() ?? '',
      pickupLat: double.tryParse('${json['pickup_lat'] ?? ''}'),
      pickupLng: double.tryParse('${json['pickup_lng'] ?? ''}'),
      dropoffLat: double.tryParse('${json['dropoff_lat'] ?? ''}'),
      dropoffLng: double.tryParse('${json['dropoff_lng'] ?? ''}'),
      distanceDriverToPickupLabel:
          (json['distance_driver_to_pickup_label'] ??
                  json['distance_to_pickup_label'])
              ?.toString(),
      routeDistanceLabel: json['route_distance_label']?.toString(),
      driver: json['driver'] is Map
          ? OrderTrackingDriver.fromJson(
              Map<String, dynamic>.from(json['driver'] as Map),
            )
          : null,
      customer: json['customer'] is Map
          ? OrderTrackingDriver.fromJson(
              Map<String, dynamic>.from(json['customer'] as Map),
            )
          : null,
      contactPhone: () {
        final raw = (json['contact_phone'] ??
                json['customer_contact_phone'] ??
                json['customer_phone'] ??
                json['order_phone'] ??
                json['phone'])
            ?.toString()
            .trim();
        if (raw == null || raw.isEmpty || raw == 'null') return null;
        return raw;
      }(),
      rideBookId: int.tryParse('${json['ride_book_id'] ?? ''}'),
      partnerUserId: int.tryParse('${json['partner_user_id'] ?? ''}'),
      chatRoomId: json['chat_room_id']?.toString(),
      canChat: false,
      canCall: _orderTrackingTruthy(json['can_call']),
      canHandToDriver: _orderTrackingTruthy(json['can_hand_to_driver']),
      canEndOrder: _orderTrackingTruthy(json['can_end_order']),
      canConfirmDelivery: _orderTrackingTruthy(json['can_confirm_delivery']),
      canGoToPickup: _orderTrackingTruthy(json['can_go_to_pickup']),
      canMarkPickedUp: _orderTrackingTruthy(json['can_mark_picked_up']),
      handedToDriver: _orderTrackingTruthy(json['handed_to_driver']),
      isCompleted: _orderTrackingTruthy(json['is_completed']) ||
          json['status']?.toString() == 'completed',
      rateeUserId: int.tryParse('${json['ratee_user_id'] ?? ''}'),
      merchantId: int.tryParse('${json['merchant_id'] ?? ''}'),
      merchantName: json['merchant_name']?.toString(),
      merchantImage: json['merchant_image']?.toString(),
      merchantPhone: () {
        final raw = json['merchant_phone']?.toString().trim();
        if (raw == null || raw.isEmpty || raw == 'null') return null;
        return raw;
      }(),
      merchantRating:
          double.tryParse('${json['merchant_rating'] ?? 0}') ?? 0,
      merchantRatingsCount:
          int.tryParse('${json['merchant_ratings_count'] ?? 0}') ?? 0,
      viewerRole: (json['viewer_role'] ?? 'customer').toString(),
    );
  }

  bool get isPlaceOrder =>
      type == 'service_order' || type == 'custom_order';

  bool get hasAssignedDriver => driver != null && driver!.id > 0;

  OrderTrackingDriver get placeOwner => OrderTrackingDriver(
        id: merchantId ?? 0,
        name: (merchantName ?? '').trim().isEmpty
            ? 'صاحب المكان'
            : merchantName!,
        image: merchantImage,
        phone: merchantPhone,
        rating: merchantRating,
        ratingsCount: merchantRatingsCount,
      );

  /// طلب مكان بدون سائق معيّن — نعرض صاحب المتجر/العيادة وليس سائق.
  bool get showPlaceOwner => isPlaceOrder && !hasAssignedDriver;

  String get displayStatusLabel {
    final s = status.toLowerCase().trim();
    final label = statusLabel.trim();
    if (isPlaceOrder &&
        (s == 'new' ||
            label == 'جديد' ||
            label.startsWith('جديد'))) {
      return 'بانتظار قبول المتجر';
    }
    return label.isEmpty ? status : label;
  }

  /// طلبات المتجر: الإلغاء قبل قبول النشاط فقط.
  bool get showEndOrderButton {
    if (!canEndOrder || handedToDriver || status.toLowerCase() == 'picked_up') {
      return false;
    }
    if (!isPlaceOrder) return true;
    final s = status.toLowerCase().trim();
    return s == 'new' || s == 'pending_vendor' || s == 'priced';
  }

  /// غرفة Firebase ثابتة لنوع الطلب + رقم الطلب.
  String get effectiveChatRoomId {
    final fromApi = (chatRoomId ?? '').trim();
    if (fromApi.isNotEmpty && fromApi != 'null') return fromApi;
    if (type.isNotEmpty && id > 0) return '${type}_$id';
    final legacy = rideBookId;
    if (legacy != null && legacy > 0) return 'ride_$legacy';
    return '';
  }
}
