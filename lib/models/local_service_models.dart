import 'package:flutter/material.dart';

class ServiceCategoryItem {
  final int id;
  final String slug;
  final String name;
  final String? icon;

  ServiceCategoryItem({
    required this.id,
    required this.slug,
    required this.name,
    this.icon,
  });

  factory ServiceCategoryItem.fromJson(Map<String, dynamic> json) {
    return ServiceCategoryItem(
      id: json['id'] as int? ?? 0,
      slug: json['slug']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      icon: json['icon']?.toString(),
    );
  }

  IconData get materialIcon {
    switch (slug) {
      case 'restaurants':
        return Icons.restaurant;
      case 'pharmacies':
        return Icons.local_pharmacy;
      case 'supermarkets':
        return Icons.shopping_cart;
      case 'hotels':
        return Icons.hotel;
      case 'clothing':
        return Icons.checkroom;
      case 'gifts_flowers':
        return Icons.local_florist;
      default:
        return Icons.storefront;
    }
  }
}

class PaymentMethodOption {
  final String key;
  final String label;

  PaymentMethodOption({required this.key, required this.label});

  factory PaymentMethodOption.fromJson(Map<String, dynamic> json) {
    return PaymentMethodOption(
      key: json['key']?.toString() ?? '',
      label: json['label']?.toString() ?? '',
    );
  }

  static List<PaymentMethodOption> dedupe(List<PaymentMethodOption> raw) {
    final out = <PaymentMethodOption>[];
    final seenLabels = <String>{};
    var seenCod = false;
    for (final m in raw) {
      final key = m.key.toLowerCase().trim();
      final label = m.label.trim();
      final isCod =
          key == 'cash' ||
          key == 'on_delivery' ||
          key == 'cod' ||
          key == 'cash_on_delivery' ||
          key == 'pay_on_delivery' ||
          label.contains('الاستلام');
      if (isCod) {
        if (seenCod) continue;
        seenCod = true;
        out.add(PaymentMethodOption(key: 'cash', label: 'دفع عند الاستلام'));
        seenLabels.add('دفع عند الاستلام');
        continue;
      }
      if (label.isEmpty || seenLabels.contains(label)) continue;
      seenLabels.add(label);
      out.add(m);
    }
    return out;
  }
}

class MerchantListItem {
  final int id;
  final String name;
  final String? image;
  final String? address;
  final bool isOpen;
  final String? distanceLabel;
  final double avgRating;
  final int ratingsCount;
  final List<PaymentMethodOption> paymentMethods;

  MerchantListItem({
    required this.id,
    required this.name,
    this.image,
    this.address,
    this.isOpen = true,
    this.distanceLabel,
    this.avgRating = 0,
    this.ratingsCount = 0,
    this.paymentMethods = const [],
  });

  factory MerchantListItem.fromJson(Map<String, dynamic> json) {
    return MerchantListItem(
      id: json['id'] as int? ?? 0,
      name: json['name']?.toString() ?? '',
      image: json['image']?.toString(),
      address: json['address']?.toString(),
      isOpen: json['is_open'] == true,
      distanceLabel: json['distance_label']?.toString(),
      avgRating: double.tryParse('${json['avg_rating'] ?? 0}') ?? 0,
      ratingsCount: int.tryParse('${json['ratings_count'] ?? 0}') ?? 0,
      paymentMethods: PaymentMethodOption.dedupe(
        (json['payment_methods'] as List? ?? [])
            .map((e) => PaymentMethodOption.fromJson(e as Map<String, dynamic>))
            .toList(),
      ),
    );
  }
}

class MerchantProductItem {
  final int id;
  final String name;
  final double price;
  final String? description;
  final String? image;

  MerchantProductItem({
    required this.id,
    required this.name,
    required this.price,
    this.description,
    this.image,
  });

  factory MerchantProductItem.fromJson(Map<String, dynamic> json) {
    return MerchantProductItem(
      id: json['id'] as int? ?? 0,
      name: json['name']?.toString() ?? '',
      price: double.tryParse(json['price']?.toString() ?? '') ?? 0,
      description: json['description']?.toString(),
      image: json['image']?.toString(),
    );
  }
}

class MerchantDetail {
  final int id;
  final String name;
  final String? image;
  final String? address;
  final bool isOpen;
  final double avgRating;
  final int ratingsCount;
  final double? lat;
  final double? lng;
  final String? walletNumber;
  final String? walletOwnerDisplay;
  final String? walletType;
  final List<PaymentMethodOption> paymentMethods;
  final List<MerchantProductItem> products;

  MerchantDetail({
    required this.id,
    required this.name,
    this.image,
    this.address,
    this.isOpen = true,
    this.avgRating = 0,
    this.ratingsCount = 0,
    this.lat,
    this.lng,
    this.walletNumber,
    this.walletOwnerDisplay,
    this.walletType,
    this.paymentMethods = const [],
    this.products = const [],
  });

  factory MerchantDetail.fromJson(Map<String, dynamic> json) {
    return MerchantDetail(
      id: json['id'] as int? ?? 0,
      name: json['name']?.toString() ?? '',
      image: json['image']?.toString(),
      address: json['address']?.toString(),
      isOpen: json['is_open'] == true,
      avgRating: double.tryParse('${json['avg_rating'] ?? 0}') ?? 0,
      ratingsCount: int.tryParse('${json['ratings_count'] ?? 0}') ?? 0,
      lat: double.tryParse('${json['lat'] ?? ''}'),
      lng: double.tryParse('${json['lng'] ?? ''}'),
      walletNumber: json['wallet_number']?.toString(),
      walletOwnerDisplay: json['wallet_owner_display']?.toString(),
      walletType: json['wallet_type']?.toString(),
      paymentMethods: PaymentMethodOption.dedupe(
        (json['payment_methods'] as List? ?? [])
            .map((e) => PaymentMethodOption.fromJson(e as Map<String, dynamic>))
            .toList(),
      ),
      products:
          (json['products'] as List? ?? [])
              .map(
                (e) => MerchantProductItem.fromJson(e as Map<String, dynamic>),
              )
              .toList(),
    );
  }
}

class ServiceOrderItem {
  final int id;
  final String orderType;
  final int? merchantId;
  final String? merchantName;
  final String? merchantPhone;
  final String productName;
  final double productPrice;
  final String? productDescription;
  final String? customRequestText;
  final String? customRequestImage;
  final int quantity;
  final double totalPrice;
  final double? merchantOfferPrice;
  final String? merchantOfferNotes;
  final String? notes;
  final String? customerContactPhone;
  final String deliveryAddress;
  final String paymentMethod;
  final String paymentMethodLabel;
  final String status;
  final String statusLabel;
  final bool canAcceptOffer;
  final bool canRejectOffer;
  final String? createdAt;
  final String fulfillmentType;
  final String fulfillmentLabel;
  final bool canChooseFulfillment;

  ServiceOrderItem({
    required this.id,
    this.orderType = 'catalog',
    this.merchantId,
    this.merchantName,
    this.merchantPhone,
    required this.productName,
    required this.productPrice,
    this.productDescription,
    this.customRequestText,
    this.customRequestImage,
    required this.quantity,
    required this.totalPrice,
    this.merchantOfferPrice,
    this.merchantOfferNotes,
    this.notes,
    this.customerContactPhone,
    required this.deliveryAddress,
    required this.paymentMethod,
    required this.paymentMethodLabel,
    required this.status,
    required this.statusLabel,
    this.canAcceptOffer = false,
    this.canRejectOffer = false,
    this.createdAt,
    this.fulfillmentType = 'pending',
    this.fulfillmentLabel = 'بانتظار اختيارك',
    this.canChooseFulfillment = false,
  });

  bool get isCustom => orderType == 'custom';

  /// مكتمل فقط بعد تسليم السائق للعميل — ليس عند قبول المتجر/قبول السعر.
  bool get isCompleted => status == 'completed';

  bool get isClosed =>
      isCompleted ||
      status == 'cancelled' ||
      status == 'rejected' ||
      status == 'merchant_rejected' ||
      status == 'offer_rejected';

  bool get needsAction =>
      canAcceptOffer || canRejectOffer || canChooseFulfillment;

  /// جاري التنفيذ: تجهيز / تعيين سائق / توصيل
  bool get isInProgress => !needsAction && !isClosed;

  bool get canContactMerchant =>
      (merchantPhone ?? '').trim().isNotEmpty &&
      (status == 'priced' ||
          status == 'accepted' ||
          status == 'merchant_accepted' ||
          status == 'preparing' ||
          status == 'driver_assigned' ||
          status == 'in_progress' ||
          status == 'completed');

  factory ServiceOrderItem.fromJson(Map<String, dynamic> json) {
    final fulfillment = (json['fulfillment_type'] ?? 'pending').toString();
    return ServiceOrderItem(
      id: json['id'] as int? ?? 0,
      orderType: json['order_type']?.toString() ?? 'catalog',
      merchantId: json['merchant_id'] as int?,
      merchantName: json['merchant_name']?.toString(),
      merchantPhone: json['merchant_phone']?.toString(),
      productName: json['product_name']?.toString() ?? '',
      productPrice:
          double.tryParse(json['product_price']?.toString() ?? '') ?? 0,
      productDescription: json['product_description']?.toString(),
      customRequestText: json['custom_request_text']?.toString(),
      customRequestImage: json['custom_request_image']?.toString(),
      quantity: json['quantity'] as int? ?? 1,
      totalPrice: double.tryParse(json['total_price']?.toString() ?? '') ?? 0,
      merchantOfferPrice: double.tryParse(
        json['merchant_offer_price']?.toString() ?? '',
      ),
      merchantOfferNotes: json['merchant_offer_notes']?.toString(),
      notes: json['notes']?.toString(),
      customerContactPhone: json['customer_contact_phone']?.toString(),
      deliveryAddress: json['delivery_address']?.toString() ?? '',
      paymentMethod: json['payment_method']?.toString() ?? '',
      paymentMethodLabel: json['payment_method_label']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      statusLabel: json['status_label']?.toString() ?? '',
      canAcceptOffer: json['can_accept_offer'] == true,
      canRejectOffer: json['can_reject_offer'] == true,
      createdAt: json['created_at']?.toString(),
      fulfillmentType: fulfillment,
      fulfillmentLabel:
          (json['fulfillment_label'] ??
                  (fulfillment == 'pickup'
                      ? 'استلام من الفرع'
                      : fulfillment == 'merchant_delivery'
                      ? 'التوصيل بواسطة المكان'
                      : 'بانتظار اختيارك'))
              .toString(),
      canChooseFulfillment:
          json['can_choose_fulfillment'] == true ||
          ((json['status']?.toString() == 'preparing' ||
                  json['status']?.toString() == 'accepted' ||
                  json['status']?.toString() == 'merchant_accepted') &&
              fulfillment == 'pending'),
    );
  }
}

class DriverServiceOrderItem {
  final int id;
  final String? pickupFrom;
  final String? deliverTo;
  final String? distanceLabel;
  final String? paymentMethodLabel;
  final String productName;
  final double totalPrice;
  final double? myOfferAmount;

  DriverServiceOrderItem({
    required this.id,
    this.pickupFrom,
    this.deliverTo,
    this.distanceLabel,
    this.paymentMethodLabel,
    required this.productName,
    required this.totalPrice,
    this.myOfferAmount,
  });

  factory DriverServiceOrderItem.fromJson(Map<String, dynamic> json) {
    final myOffer = json['my_offer'] as Map<String, dynamic>?;
    return DriverServiceOrderItem(
      id: json['id'] as int? ?? 0,
      pickupFrom: json['pickup_from']?.toString(),
      deliverTo: json['deliver_to']?.toString(),
      distanceLabel: json['distance_label']?.toString(),
      paymentMethodLabel: json['payment_method_label']?.toString(),
      productName: json['product_name']?.toString() ?? '',
      totalPrice: double.tryParse(json['total_price']?.toString() ?? '') ?? 0,
      myOfferAmount:
          myOffer != null
              ? double.tryParse(myOffer['amount']?.toString() ?? '')
              : null,
    );
  }
}
