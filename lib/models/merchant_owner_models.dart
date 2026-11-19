import 'package:motorent/models/local_service_models.dart';

class MerchantBusinessProfile {
  final int? id;
  final int? categoryId;
  final String? categoryName;
  final String? categorySlug;
  final String name;
  final String? image;
  final String address;
  final String phone;
  final double? lat;
  final double? lng;
  final List<WorkingDayHours> workingHours;
  final bool isOpen;
  final bool isActive;
  final double avgRating;
  final int ratingsCount;

  MerchantBusinessProfile({
    this.id,
    this.categoryId,
    this.categoryName,
    this.categorySlug,
    required this.name,
    this.image,
    required this.address,
    required this.phone,
    this.lat,
    this.lng,
    this.workingHours = const [],
    this.isOpen = true,
    this.isActive = true,
    this.avgRating = 0,
    this.ratingsCount = 0,
  });

  factory MerchantBusinessProfile.fromJson(Map<String, dynamic> json) {
    final hoursRaw = json['working_hours'];
    List<WorkingDayHours> hours = [];
    if (hoursRaw is List) {
      hours = hoursRaw
          .map((e) => WorkingDayHours.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    return MerchantBusinessProfile(
      id: json['id'] as int?,
      categoryId: json['category_id'] as int?,
      categoryName: json['category_name']?.toString(),
      categorySlug: json['category_slug']?.toString(),
      name: json['name']?.toString() ?? '',
      image: json['image']?.toString(),
      address: json['address']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      lat: double.tryParse(json['lat']?.toString() ?? ''),
      lng: double.tryParse(json['lng']?.toString() ?? ''),
      workingHours: hours,
      isOpen: json['is_open'] == true,
      isActive: json['is_active'] == true,
      avgRating: double.tryParse('${json['avg_rating'] ?? 0}') ?? 0,
      ratingsCount: int.tryParse('${json['ratings_count'] ?? 0}') ?? 0,
    );
  }

  List<Map<String, dynamic>> workingHoursToJson() {
    return workingHours.map((e) => e.toJson()).toList();
  }
}

class WorkingDayHours {
  final String dayKey;
  final String label;
  final String open;
  final String close;
  final bool isClosed;

  WorkingDayHours({
    required this.dayKey,
    required this.label,
    required this.open,
    required this.close,
    this.isClosed = false,
  });

  factory WorkingDayHours.fromJson(Map<String, dynamic> json) {
    return WorkingDayHours(
      dayKey: json['day_key']?.toString() ?? '',
      label: json['label']?.toString() ?? '',
      open: json['open']?.toString() ?? '09:00',
      close: json['close']?.toString() ?? '22:00',
      isClosed: json['is_closed'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
        'day_key': dayKey,
        'label': label,
        'open': open,
        'close': close,
        'is_closed': isClosed,
      };

  static List<WorkingDayHours> defaults() => [
        WorkingDayHours(dayKey: 'saturday', label: 'السبت', open: '09:00', close: '22:00'),
        WorkingDayHours(dayKey: 'sunday', label: 'الأحد', open: '09:00', close: '22:00'),
        WorkingDayHours(dayKey: 'monday', label: 'الاثنين', open: '09:00', close: '22:00'),
        WorkingDayHours(dayKey: 'tuesday', label: 'الثلاثاء', open: '09:00', close: '22:00'),
        WorkingDayHours(dayKey: 'wednesday', label: 'الأربعاء', open: '09:00', close: '22:00'),
        WorkingDayHours(dayKey: 'thursday', label: 'الخميس', open: '09:00', close: '22:00'),
        WorkingDayHours(dayKey: 'friday', label: 'الجمعة', open: '09:00', close: '22:00', isClosed: true),
      ];
}

class MerchantProfilePayload {
  final MerchantBusinessProfile? merchant;
  final List<ServiceCategoryItem> categories;

  MerchantProfilePayload({
    this.merchant,
    required this.categories,
  });

  factory MerchantProfilePayload.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? json;
    final merchantJson = data['merchant'];
    return MerchantProfilePayload(
      merchant: merchantJson is Map<String, dynamic>
          ? MerchantBusinessProfile.fromJson(merchantJson)
          : null,
      categories: (data['categories'] as List? ?? [])
          .map((e) => ServiceCategoryItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class MerchantProductItem {
  final int id;
  final String name;
  final double price;
  final String? description;
  final String? image;
  final bool isActive;
  final int sortOrder;

  MerchantProductItem({
    required this.id,
    required this.name,
    required this.price,
    this.description,
    this.image,
    this.isActive = true,
    this.sortOrder = 0,
  });

  factory MerchantProductItem.fromJson(Map<String, dynamic> json) {
    return MerchantProductItem(
      id: json['id'] as int? ?? 0,
      name: json['name']?.toString() ?? '',
      price: double.tryParse(json['price']?.toString() ?? '') ?? 0,
      description: json['description']?.toString(),
      image: json['image']?.toString(),
      isActive: json['is_active'] == true,
      sortOrder: json['sort_order'] as int? ?? 0,
    );
  }
}

class MerchantProductsPayload {
  final int merchantId;
  final String merchantName;
  final int maxProducts;
  final int count;
  final List<MerchantProductItem> products;

  MerchantProductsPayload({
    required this.merchantId,
    required this.merchantName,
    required this.maxProducts,
    required this.count,
    required this.products,
  });

  factory MerchantProductsPayload.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? json;
    return MerchantProductsPayload(
      merchantId: data['merchant_id'] as int? ?? 0,
      merchantName: data['merchant_name']?.toString() ?? '',
      maxProducts: data['max_products'] as int? ?? 10,
      count: data['count'] as int? ?? 0,
      products: (data['products'] as List? ?? [])
          .map((e) => MerchantProductItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  bool get canAddMore => count < maxProducts;
}

class MerchantOrderCustomer {
  final int id;
  final String name;
  final String? phone;
  final String? email;
  final double avgRating;
  final int ratingsCount;

  MerchantOrderCustomer({
    required this.id,
    required this.name,
    this.phone,
    this.email,
    this.avgRating = 0,
    this.ratingsCount = 0,
  });

  factory MerchantOrderCustomer.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return MerchantOrderCustomer(id: 0, name: '');
    }
    return MerchantOrderCustomer(
      id: json['id'] as int? ?? 0,
      name: json['name']?.toString() ?? '',
      phone: json['phone']?.toString(),
      email: json['email']?.toString(),
      avgRating: double.tryParse('${json['avg_rating'] ?? 0}') ?? 0,
      ratingsCount: int.tryParse('${json['ratings_count'] ?? 0}') ?? 0,
    );
  }
}

class MerchantServiceOrder {
  final int id;
  final String orderType;
  final String productName;
  final double productPrice;
  final String? productDescription;
  final String? customRequestText;
  final String? customRequestImage;
  final int quantity;
  final double totalPrice;
  final double? merchantOfferPrice;
  final String? merchantOfferNotes;
  final double? commissionAmount;
  final String? notes;
  final String? customerContactPhone;
  final String deliveryAddress;
  final String? deliveryDetails;
  final String paymentMethod;
  final String paymentMethodLabel;
  final String? paymentProof;
  final String status;
  final String statusLabel;
  final MerchantOrderCustomer customer;
  final MerchantOrderDriver? invitedDriver;
  final MerchantOrderDriver? driver;
  final bool canAccept;
  final bool canReject;
  final bool canConfirmPayment;
  final bool canRejectPayment;
  final bool canSendOffer;
  final String? fulfillmentType;
  final bool isReady;
  final bool canMarkReady;
  final bool canAssignDriver;
  final bool canContact;
  final String? createdAt;

  MerchantServiceOrder({
    required this.id,
    this.orderType = 'catalog',
    required this.productName,
    required this.productPrice,
    this.productDescription,
    this.customRequestText,
    this.customRequestImage,
    required this.quantity,
    required this.totalPrice,
    this.merchantOfferPrice,
    this.merchantOfferNotes,
    this.commissionAmount,
    this.notes,
    this.customerContactPhone,
    required this.deliveryAddress,
    this.deliveryDetails,
    required this.paymentMethod,
    required this.paymentMethodLabel,
    this.paymentProof,
    required this.status,
    required this.statusLabel,
    required this.customer,
    this.invitedDriver,
    this.driver,
    this.canAccept = false,
    this.canReject = false,
    this.canConfirmPayment = false,
    this.canRejectPayment = false,
    this.canSendOffer = false,
    this.fulfillmentType,
    this.isReady = false,
    this.canMarkReady = false,
    this.canAssignDriver = false,
    this.canContact = false,
    this.createdAt,
  });

  bool get isCustom => orderType == 'custom';

  factory MerchantServiceOrder.fromJson(Map<String, dynamic> json) {
    return MerchantServiceOrder(
      id: json['id'] as int? ?? 0,
      orderType: json['order_type']?.toString() ?? 'catalog',
      productName: json['product_name']?.toString() ?? '',
      productPrice: double.tryParse(json['product_price']?.toString() ?? '') ?? 0,
      productDescription: json['product_description']?.toString(),
      customRequestText: json['custom_request_text']?.toString(),
      customRequestImage: json['custom_request_image']?.toString(),
      quantity: json['quantity'] as int? ?? 1,
      totalPrice: double.tryParse(json['total_price']?.toString() ?? '') ?? 0,
      merchantOfferPrice:
          double.tryParse(json['merchant_offer_price']?.toString() ?? ''),
      merchantOfferNotes: json['merchant_offer_notes']?.toString(),
      commissionAmount:
          double.tryParse(json['commission_amount']?.toString() ?? ''),
      notes: json['notes']?.toString(),
      customerContactPhone: json['customer_contact_phone']?.toString(),
      deliveryAddress: json['delivery_address']?.toString() ?? '',
      deliveryDetails: json['delivery_details']?.toString(),
      paymentMethod: json['payment_method']?.toString() ?? '',
      paymentMethodLabel: json['payment_method_label']?.toString() ?? '',
      paymentProof: json['payment_proof']?.toString(),
      status: json['status']?.toString() ?? '',
      statusLabel: json['status_label']?.toString() ?? '',
      customer: MerchantOrderCustomer.fromJson(
        json['customer'] as Map<String, dynamic>?,
      ),
      invitedDriver: MerchantOrderDriver.fromJson(
        json['invited_driver'] as Map<String, dynamic>?,
      ),
      driver: MerchantOrderDriver.fromJson(
        json['driver'] as Map<String, dynamic>?,
      ),
      canAccept: json['can_accept'] == true,
      canReject: json['can_reject'] == true,
      canConfirmPayment: json['can_confirm_payment'] == true,
      canRejectPayment: json['can_reject_payment'] == true,
      canSendOffer: json['can_send_offer'] == true,
      fulfillmentType: json['fulfillment_type']?.toString(),
      isReady: json['is_ready'] == true,
      canMarkReady: json['can_mark_ready'] == true,
      canAssignDriver: json['can_assign_driver'] == true,
      canContact: json['can_contact'] == true,
      createdAt: json['created_at']?.toString(),
    );
  }

  bool get isWallet => paymentMethod == 'wallet';
  bool get isPickup => fulfillmentType == 'pickup';
  bool get isMerchantDelivery => fulfillmentType == 'merchant_delivery';
  bool get isPending =>
      canAccept ||
      canReject ||
      canConfirmPayment ||
      canRejectPayment ||
      canSendOffer ||
      canAssignDriver;

  /// اكتمل فعلياً بعد تسليم السائق للعميل فقط — ليس بمجرد قبول الطلب.
  bool get isCompleted => status == 'completed';

  bool get isClosed =>
      isCompleted ||
      status == 'cancelled' ||
      status == 'rejected' ||
      status == 'merchant_rejected' ||
      status == 'offer_unavailable' ||
      status == 'offer_rejected';

  /// بعد قبول التاجر ولحد التسليم — لسه جاري مش مكتمل.
  bool get isInProgress {
    final s = status.toLowerCase();
    if (isClosed || isPending) return false;
    return s == 'preparing' ||
        s == 'accepted' ||
        s == 'driver_assigned' ||
        s == 'in_progress' ||
        (!isClosed && !isPending);
  }
}

class MerchantOrderDriver {
  final int id;
  final String name;
  final String? phone;

  MerchantOrderDriver({
    required this.id,
    required this.name,
    this.phone,
  });

  factory MerchantOrderDriver.fromJson(Map<String, dynamic>? json) {
    if (json == null) return MerchantOrderDriver(id: 0, name: '');
    return MerchantOrderDriver(
      id: json['id'] as int? ?? 0,
      name: json['name']?.toString() ?? '',
      phone: json['phone']?.toString(),
    );
  }

  bool get isValid => id > 0;
}

class MerchantAvailableDriver {
  final int id;
  final String name;
  final String? phone;
  final String? vehicleType;

  MerchantAvailableDriver({
    required this.id,
    required this.name,
    this.phone,
    this.vehicleType,
  });

  factory MerchantAvailableDriver.fromJson(Map<String, dynamic> json) {
    return MerchantAvailableDriver(
      id: json['id'] as int? ?? 0,
      name: json['name']?.toString() ?? '',
      phone: json['phone']?.toString(),
      vehicleType: json['vehicle_type']?.toString(),
    );
  }
}

class MerchantPaymentSettings {
  final bool payOnDelivery;
  final bool payWallet;
  final String? walletNumber;
  final String? walletOwnerName;
  final String? walletOwnerDisplay;
  final String? walletType;

  MerchantPaymentSettings({
    required this.payOnDelivery,
    required this.payWallet,
    this.walletNumber,
    this.walletOwnerName,
    this.walletOwnerDisplay,
    this.walletType,
  });

  factory MerchantPaymentSettings.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? json;
    return MerchantPaymentSettings(
      payOnDelivery: data['pay_on_delivery'] == true,
      payWallet: data['pay_wallet'] == true,
      walletNumber: data['wallet_number']?.toString(),
      walletOwnerName: data['wallet_owner_name']?.toString(),
      walletOwnerDisplay: data['wallet_owner_display']?.toString(),
      walletType: data['wallet_type']?.toString(),
    );
  }

  static String maskOwnerName(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '';
    if (parts.length == 1) return parts.first;
    final buffer = StringBuffer(parts.first);
    for (var i = 1; i < parts.length && i < 3; i++) {
      if (parts[i].isNotEmpty) buffer.write(' ${parts[i][0]}');
    }
    return buffer.toString();
  }
}

class MerchantOrdersPayload {
  final int pendingCount;
  final List<MerchantServiceOrder> orders;

  MerchantOrdersPayload({
    required this.pendingCount,
    required this.orders,
  });

  factory MerchantOrdersPayload.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? json;
    return MerchantOrdersPayload(
      pendingCount: data['pending_count'] as int? ?? 0,
      orders: (data['orders'] as List? ?? [])
          .map((e) => MerchantServiceOrder.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
