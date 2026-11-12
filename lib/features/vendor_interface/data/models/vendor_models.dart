import 'package:motorent/features/vendor_interface/domain/entities/vendor_entities.dart';

class VendorCategoryModel extends VendorCategory {
  const VendorCategoryModel({
    required super.id,
    required super.slug,
    required super.name,
    super.hubSection,
  });

  factory VendorCategoryModel.fromJson(Map<String, dynamic> json) {
    final slug = (json['slug'] ?? '').toString();
    final name = (json['name'] ?? '').toString();
    final rawHub = (json['hub_section'] ?? json['hubSection'] ?? '')
        .toString()
        .trim()
        .toLowerCase();
    final hub = (rawHub == 'orders' ||
            rawHub == 'bookings' ||
            rawHub == 'services')
        ? rawHub
        : _inferVendorHub(slug, name);
    return VendorCategoryModel(
      id: _asInt(json['id']),
      slug: slug,
      name: name,
      hubSection: hub,
    );
  }
}

String _inferVendorHub(String slug, String name) {
  final hay = '$slug $name'.toLowerCase();
  if (RegExp(
          r'hotel|فندق|عياد|اسنان|أسنان|صالون|جيم|clinic|dental|salon|gym|spa')
      .hasMatch(hay)) {
    return 'bookings';
  }
  if (RegExp(
          r'سباك|كهرب|نجار|نقاش|ميكانيك|plumber|electric|carpenter|teacher|profession')
      .hasMatch(hay)) {
    return 'services';
  }
  return 'orders';
}

class VendorWorkingHoursModel extends VendorWorkingHours {
  const VendorWorkingHoursModel({
    required super.dayKey,
    required super.label,
    required super.open,
    required super.close,
    super.isClosed,
  });

  factory VendorWorkingHoursModel.fromJson(Map<String, dynamic> json) {
    final dayKey = (json['day_key'] ?? json['day'] ?? '').toString();
    const labels = {
      'saturday': 'السبت',
      'sunday': 'الأحد',
      'monday': 'الاثنين',
      'tuesday': 'الثلاثاء',
      'wednesday': 'الأربعاء',
      'thursday': 'الخميس',
      'friday': 'الجمعة',
    };
    final rawClosed = json['is_closed'] ?? json['closed'] ?? false;
    final isClosed =
        rawClosed == true ||
        rawClosed == 1 ||
        rawClosed == '1' ||
        rawClosed == 'true';
    return VendorWorkingHoursModel(
      dayKey: dayKey,
      label: (json['label'] ?? labels[dayKey] ?? dayKey).toString(),
      open: (json['open'] ?? '09:00').toString(),
      close: (json['close'] ?? '22:00').toString(),
      isClosed: isClosed,
    );
  }
}

class VendorStoreModel extends VendorStore {
  const VendorStoreModel({
    super.id,
    super.categoryId,
    super.name,
    super.image,
    super.address,
    super.phone,
    super.lat,
    super.lng,
    super.workingHours,
    super.payOnDelivery,
    super.payWallet,
    super.walletNumber,
    super.walletOwnerName,
    super.walletType,
    super.listingKind,
    super.categories,
  });

  factory VendorStoreModel.fromJson(
    Map<String, dynamic> json, {
    List<VendorCategory>? categories,
    Map<String, dynamic>? payment,
  }) {
    final hoursRaw = json['working_hours'];
    final hours =
        hoursRaw is List
            ? hoursRaw
                .whereType<Map>()
                .map(
                  (e) => VendorWorkingHoursModel.fromJson(
                    Map<String, dynamic>.from(e),
                  ),
                )
                .toList()
            : <VendorWorkingHours>[];

    final pay = payment ?? json;

    return VendorStoreModel(
      id: _asIntOrNull(json['id']),
      categoryId: _asIntOrNull(json['category_id']),
      name: (json['name'] ?? '').toString(),
      image: json['image']?.toString(),
      address: (json['address'] ?? '').toString(),
      phone: (json['phone'] ?? '').toString(),
      lat: _asDouble(json['lat']),
      lng: _asDouble(json['lng']),
      workingHours: hours.isEmpty ? VendorWorkingHours.defaults() : hours,
      payOnDelivery:
          pay['pay_on_delivery'] == true ||
          pay['pay_on_delivery'] == 1 ||
          pay['payOnDelivery'] == true ||
          pay['accepts_cash'] == true ||
          pay['accepts_cash'] == 1,
      payWallet:
          pay['pay_wallet'] == true ||
          pay['pay_wallet'] == 1 ||
          pay['payWallet'] == true ||
          pay['accepts_wallet'] == true ||
          pay['accepts_wallet'] == 1,
      walletNumber: (pay['wallet_number'] ?? pay['walletNumber'])?.toString(),
      walletOwnerName:
          (pay['wallet_owner_name'] ??
                  pay['walletOwnerName'] ??
                  pay['wallet_holder_name'])
              ?.toString(),
      walletType: (pay['wallet_type'] ?? pay['walletType'])?.toString(),
      listingKind: ((json['listing_kind'] ?? json['listingKind'] ?? 'place')
              .toString()
              .trim()
              .isEmpty)
          ? 'place'
          : (json['listing_kind'] ?? json['listingKind'] ?? 'place').toString(),
      categories: categories ?? const [],
    );
  }
}

class VendorProductModel extends VendorProduct {
  const VendorProductModel({
    required super.id,
    required super.name,
    required super.price,
    super.description,
    super.image,
    super.isActive,
  });

  factory VendorProductModel.fromJson(Map<String, dynamic> json) {
    return VendorProductModel(
      id: _asInt(json['id']),
      name: (json['name'] ?? '').toString(),
      price: _asDouble(json['price']) ?? 0,
      description: json['description']?.toString(),
      image: json['image']?.toString(),
      isActive:
          json['is_active'] == true ||
          json['is_active'] == 1 ||
          json['is_available'] == true ||
          json['is_available'] == 1 ||
          json['is_visible'] == true ||
          json['is_visible'] == 1,
    );
  }
}

class VendorOrderModel extends VendorOrder {
  const VendorOrderModel({
    required super.id,
    required super.productName,
    required super.productPrice,
    required super.totalPrice,
    super.notes,
    required super.customerName,
    super.customerPhone,
    required super.deliveryAddress,
    required super.paymentMethod,
    required super.paymentMethodLabel,
    super.paymentProof,
    required super.status,
    required super.statusLabel,
    super.canAccept,
    super.canReject,
    super.canConfirmPayment,
    super.canRejectPayment,
    super.orderType,
    super.customRequestText,
    super.customRequestImage,
    super.offerPrice,
    super.offerNotes,
    super.canSendOffer,
    super.revealCustomerContact,
    super.customerRating,
    super.customerRatingsCount,
    super.canPrepareDispatch,
    super.canViewDeliveryOffers,
    super.canMarkCompleted,
    super.vendorHint,
    super.biddingTripId,
    super.fulfillmentType,
    super.fulfillmentLabel,
    super.deliveryLat,
    super.deliveryLng,
    super.storeAddress,
    super.storeLat,
    super.storeLng,
  });

  factory VendorOrderModel.fromJson(Map<String, dynamic> json) {
    final customer = json['customer'];
    String customerName = '';
    String? customerPhone;
    double customerRating = 0;
    int customerRatingsCount = 0;
    if (customer is Map) {
      customerName = (customer['name'] ?? '').toString();
      customerPhone = customer['phone']?.toString();
      customerRating =
          _asDouble(customer['avg_rating'] ?? customer['rating']) ?? 0;
      customerRatingsCount = _asInt(
        customer['ratings_count'] ?? customer['ratingsCount'] ?? 0,
      );
    }
    customerPhone ??= json['customer_contact_phone']?.toString();
    if (customerName.isEmpty) {
      customerName = (json['customer_name'] ?? '').toString();
    }
    if (customerRating <= 0) {
      customerRating =
          _asDouble(json['customer_rating'] ?? json['customerRating']) ?? 0;
    }
    if (customerRatingsCount <= 0) {
      customerRatingsCount = _asInt(
        json['customer_ratings_count'] ?? json['customerRatingsCount'] ?? 0,
      );
    }

    final orderType = (json['order_type'] ?? 'catalog').toString();
    final status = (json['status'] ?? '').toString();
    final canSendOffer =
        json['can_send_offer'] == true ||
        (orderType == 'custom' &&
            (status == 'pending' || status == 'pending_offer') &&
            json['can_send_offer'] != false);

    final reveal =
        json['reveal_customer_contact'] == true ||
        json['customer_visible'] == true ||
        json['can_contact'] == true;

    return VendorOrderModel(
      id: _asInt(json['id']),
      productName: (json['product_name'] ?? '').toString(),
      productPrice: _asDouble(json['product_price']) ?? 0,
      totalPrice: _asDouble(json['total_price']) ?? 0,
      notes: json['notes']?.toString(),
      customerName: customerName,
      customerPhone: customerPhone,
      deliveryAddress: (json['delivery_address'] ?? '').toString(),
      paymentMethod: (json['payment_method'] ?? '').toString(),
      paymentMethodLabel: (json['payment_method_label'] ?? '').toString(),
      paymentProof: json['payment_proof']?.toString(),
      status: status,
      statusLabel: (json['status_label'] ?? json['status'] ?? '').toString(),
      canAccept: json['can_accept'] == true,
      canReject: json['can_reject'] == true,
      canConfirmPayment: json['can_confirm_payment'] == true,
      canRejectPayment: json['can_reject_payment'] == true,
      orderType: orderType,
      customRequestText: json['custom_request_text']?.toString(),
      customRequestImage: json['custom_request_image']?.toString(),
      offerPrice: _asDouble(
        json['merchant_offer_price'] ?? json['offer_price'],
      ),
      offerNotes:
          json['merchant_offer_notes']?.toString() ??
          json['offer_notes']?.toString(),
      canSendOffer: canSendOffer,
      revealCustomerContact: reveal,
      customerRating: customerRating,
      customerRatingsCount: customerRatingsCount,
      canPrepareDispatch: json['can_prepare_dispatch'] == true,
      canViewDeliveryOffers: json['can_view_delivery_offers'] == true,
      canMarkCompleted: json['can_mark_completed'] == true,
      vendorHint: json['vendor_hint']?.toString(),
      biddingTripId: int.tryParse('${json['bidding_trip_id'] ?? ''}'),
      fulfillmentType: (json['fulfillment_type'] ?? 'pending').toString(),
      fulfillmentLabel:
          (json['fulfillment_label'] ??
                  ((json['fulfillment_type']?.toString() == 'pickup')
                      ? 'استلام من المكان'
                      : (json['fulfillment_type']?.toString() ==
                          'merchant_delivery')
                      ? 'توصيل بواسطة المكان'
                      : 'بانتظار اختيار العميل'))
              .toString(),
      deliveryLat: _asDouble(json['delivery_lat']),
      deliveryLng: _asDouble(json['delivery_lng']),
      storeAddress: json['store_address']?.toString(),
      storeLat: _asDouble(json['store_lat']),
      storeLng: _asDouble(json['store_lng']),
    );
  }
}

class VendorWalletModel extends VendorWallet {
  const VendorWalletModel({
    required super.dueAmount,
    required super.commissionRate,
    required super.completedOrdersCount,
    super.bookingsCount,
    required super.walletNumber,
    required super.instapayNumber,
    super.billingMode,
    super.billingModeLabel,
    super.selectedBillingLabel,
    super.commissionOptionEnabled,
    super.fixedFeeOptionEnabled,
    super.orderCommissionPercent,
    super.orderFixedFee,
    super.debtLimit,
    super.commissionEnabled,
  });

  factory VendorWalletModel.fromJson(Map<String, dynamic> json) {
    double? parseRate(dynamic v) {
      if (v == null) return null;
      if (v is num) return v.toDouble();
      final s = v.toString().replaceAll('%', '').trim();
      return double.tryParse(s);
    }

    final billingMode =
        (json['billing_mode'] ?? 'commission').toString().trim();

    return VendorWalletModel(
      dueAmount: _asDouble(json['due_amount'] ?? json['dues_balance']) ?? 0,
      commissionRate:
          parseRate(json['commission_rate'] ?? json['commission_percent']) ??
              10,
      completedOrdersCount: _asInt(
        json['completed_orders_count'] ??
            json['completed_orders'] ??
            json['completed_trips_count'],
      ),
      bookingsCount: _asInt(
        json['bookings_count'] ?? json['place_bookings_count'],
      ),
      walletNumber:
          (json['wallet_number'] ??
                  json['app_wallet_number'] ??
                  json['vodafone_cash_number'] ??
                  '')
              .toString(),
      instapayNumber:
          (json['instapay_number'] ?? json['instapay_handle'] ?? '').toString(),
      billingMode: billingMode,
      billingModeLabel: (json['billing_mode_label'] ?? '').toString(),
      selectedBillingLabel: (json['selected_billing_label'] ?? '').toString(),
      commissionOptionEnabled: _flag(
        json['commission_option_enabled'],
        fallback: true,
      ),
      fixedFeeOptionEnabled: _flag(
        json['fixed_fee_option_enabled'],
        fallback: false,
      ),
      orderCommissionPercent: parseRate(json['order_commission_percent']) ?? 5,
      orderFixedFee: _asDouble(
            json['order_fixed_fee'] ?? json['fixed_fee_per_order'],
          ) ??
          10,
      debtLimit: _asDouble(json['debt_limit']) ?? 0,
      commissionEnabled: _flag(json['commission_enabled'], fallback: true),
    );
  }
}

bool _flag(dynamic v, {required bool fallback}) {
  if (v == null) return fallback;
  if (v == true || v == 1) return true;
  if (v == false || v == 0) return false;
  final s = v.toString().trim().toLowerCase();
  if (s.isEmpty) return fallback;
  return s == '1' || s == 'true' || s == 'yes' || s == 'on';
}

int _asInt(dynamic v) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse(v?.toString() ?? '') ?? 0;
}

int? _asIntOrNull(dynamic v) {
  if (v == null) return null;
  return _asInt(v);
}

double? _asDouble(dynamic v) {
  if (v == null) return null;
  if (v is double) return v;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString());
}
