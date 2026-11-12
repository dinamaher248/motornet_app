import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

class ServiceCategory extends Equatable {
  final int? id;
  final String slug;
  final String name;
  final IconData icon;
  final Color color;
  final String? image;
  /// orders | bookings | services | transport
  final String hubSection;

  const ServiceCategory({
    this.id,
    required this.slug,
    required this.name,
    required this.icon,
    required this.color,
    this.image,
    this.hubSection = 'orders',
  });

  static const defaults = <ServiceCategory>[
    ServiceCategory(
      slug: 'restaurant',
      name: 'المطاعم',
      icon: Icons.restaurant,
      color: Color(0xFFE8940A),
    ),
    ServiceCategory(
      slug: 'pharmacy',
      name: 'الصيدليات',
      icon: Icons.local_pharmacy,
      color: Color(0xFF0C9F6A),
    ),
    ServiceCategory(
      slug: 'supermarket',
      name: 'سوبر ماركت',
      icon: Icons.shopping_cart,
      color: Color(0xFF2563EB),
    ),
    ServiceCategory(
      slug: 'hotel',
      name: 'فنادق',
      icon: Icons.hotel,
      color: Color(0xFF7C3AED),
      hubSection: 'bookings',
    ),
    ServiceCategory(
      slug: 'other_services',
      name: 'خدمات أخرى',
      icon: Icons.handyman_outlined,
      color: Color(0xFF0F766E),
      hubSection: 'services',
    ),
  ];

  factory ServiceCategory.fromApi(Map<String, dynamic> json) {
    final slug = (json['slug'] ?? '').toString().trim().toLowerCase();
    final name = (json['name'] ?? slug).toString();
    return ServiceCategory(
      id: int.tryParse('${json['id'] ?? ''}'),
      slug: slug.isEmpty ? 'service' : slug,
      name: name,
      icon: iconForSlug(slug),
      color: colorForSlug(slug),
      image: imagePathFromApi(json['image'] ?? json['icon']),
      hubSection: resolveHubSection(
        json['hub_section']?.toString(),
        slug,
        name,
      ),
    );
  }

  /// يقبل مسار صورة فقط — يتجاهل قيم الأيقونة النصية القديمة.
  static String? imagePathFromApi(dynamic raw) {
    final value = raw?.toString().trim() ?? '';
    if (value.isEmpty) return null;
    if (value.startsWith('http://') || value.startsWith('https://')) {
      return value;
    }
    final looksLikeFile = value.contains('/') ||
        RegExp(r'\.(jpe?g|png|webp|gif)$', caseSensitive: false).hasMatch(value);
    return looksLikeFile ? value : null;
  }

  static String resolveHubSection(String? raw, String slug, String name) {
    final section = (raw ?? '').trim().toLowerCase();
    if (section == 'orders' ||
        section == 'bookings' ||
        section == 'services' ||
        section == 'transport') {
      return section;
    }
    final hay = '$slug $name'.toLowerCase();
    if (RegExp(
            r'transport|quick_trip|goods|مشوار|نقل|مواصلات')
        .hasMatch(hay)) {
      return 'transport';
    }
    if (RegExp(
            r'hotel|فندق|عياد|اسنان|أسنان|صالون|جيم|clinic|dental|salon|gym|spa')
        .hasMatch(hay)) {
      return 'bookings';
    }
    if (RegExp(
            r'profession|سباك|كهرب|نجار|نقاش|ميكانيك|معلم|plumber|electric|carpenter|teacher')
        .hasMatch(hay)) {
      return 'services';
    }
    return 'orders';
  }

  static IconData iconForSlug(String slug) {
    switch (slug) {
      case 'restaurant':
      case 'restaurants':
        return Icons.restaurant;
      case 'pharmacy':
      case 'pharmacies':
        return Icons.local_pharmacy;
      case 'supermarket':
      case 'supermarkets':
        return Icons.shopping_cart;
      case 'hotel':
      case 'hotels':
        return Icons.hotel;
      case 'dental':
      case 'clinic':
      case 'clinics':
        return Icons.medical_services_outlined;
      case 'clothing':
        return Icons.checkroom;
      case 'gifts':
      case 'gifts_flowers':
        return Icons.local_florist;
      case 'quick_trip':
      case 'transport':
        return Icons.two_wheeler;
      case 'goods':
        return Icons.local_shipping_outlined;
      default:
        return Icons.storefront;
    }
  }

  static Color colorForSlug(String slug) {
    switch (slug) {
      case 'restaurant':
      case 'restaurants':
        return const Color(0xFFE8940A);
      case 'pharmacy':
      case 'pharmacies':
        return const Color(0xFF0C9F6A);
      case 'supermarket':
      case 'supermarkets':
        return const Color(0xFF2563EB);
      case 'hotel':
      case 'hotels':
        return const Color(0xFF7C3AED);
      case 'dental':
      case 'clinic':
      case 'clinics':
        return const Color(0xFF0C9F6A);
      case 'clothing':
        return const Color(0xFFDB2777);
      case 'gifts':
      case 'gifts_flowers':
        return const Color(0xFF059669);
      case 'quick_trip':
      case 'transport':
        return const Color(0xFFE8940A);
      case 'goods':
        return const Color(0xFF0C9F6A);
      default:
        return const Color(0xFF0F766E);
    }
  }

  String get nearbyTitle {
    switch (slug) {
      case 'restaurant':
      case 'restaurants':
        return 'مطاعم قريبة منك';
      case 'pharmacy':
      case 'pharmacies':
        return 'صيدليات قريبة منك';
      case 'supermarket':
      case 'supermarkets':
        return 'سوبر ماركت قريب منك';
      case 'hotel':
      case 'hotels':
        return 'فنادق قريبة منك';
      default:
        return '$name قريبة منك';
    }
  }

  @override
  List<Object?> get props => [id, slug, name, hubSection];
}

class PaymentMethod extends Equatable {
  final String key;
  final String label;

  const PaymentMethod({required this.key, required this.label});

  bool get isCash =>
      key == 'cash' || key == 'cod' || key == 'on_delivery';
  bool get isWallet => key == 'wallet' || key == 'e_wallet';

  @override
  List<Object?> get props => [key, label];
}

class Store extends Equatable {
  final int id;
  final String name;
  final String? image;
  final String? address;
  final bool isOpen;
  final String? distanceLabel;
  final double? distanceM;
  final double? lat;
  final double? lng;
  final double avgRating;
  final int ratingsCount;
  final List<PaymentMethod> paymentMethods;
  final String? walletNumber;
  final String? walletOwnerDisplay;
  final String? phone;
  final List<ServiceProduct> products;

  const Store({
    required this.id,
    required this.name,
    this.image,
    this.address,
    this.isOpen = true,
    this.distanceLabel,
    this.distanceM,
    this.lat,
    this.lng,
    this.avgRating = 0,
    this.ratingsCount = 0,
    this.paymentMethods = const [],
    this.walletNumber,
    this.walletOwnerDisplay,
    this.phone,
    this.products = const [],
  });

  String get statusLabel => isOpen ? 'مفتوح الآن' : 'مغلق';

  Store copyWith({
    List<ServiceProduct>? products,
    String? distanceLabel,
    double? distanceM,
    double? avgRating,
    int? ratingsCount,
  }) {
    return Store(
      id: id,
      name: name,
      image: image,
      address: address,
      isOpen: isOpen,
      distanceLabel: distanceLabel ?? this.distanceLabel,
      distanceM: distanceM ?? this.distanceM,
      lat: lat,
      lng: lng,
      avgRating: avgRating ?? this.avgRating,
      ratingsCount: ratingsCount ?? this.ratingsCount,
      paymentMethods: paymentMethods,
      walletNumber: walletNumber,
      walletOwnerDisplay: walletOwnerDisplay,
      phone: phone,
      products: products ?? this.products,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        image,
        address,
        isOpen,
        distanceLabel,
        distanceM,
        lat,
        lng,
        avgRating,
        ratingsCount,
        paymentMethods,
        walletNumber,
        products,
      ];
}

class ServiceProduct extends Equatable {
  final int id;
  final String name;
  final double price;
  final String? description;
  final String? image;

  const ServiceProduct({
    required this.id,
    required this.name,
    required this.price,
    this.description,
    this.image,
  });

  @override
  List<Object?> get props => [id, name, price, description, image];
}

class CheckoutParams extends Equatable {
  final int storeId;
  final int productId;
  final int quantity;
  final double productTotal;
  final String? notes;
  final String deliveryAddress;
  final double? deliveryLat;
  final double? deliveryLng;
  final String paymentMethod;
  final String? walletReceiptPath;
  /// pickup | merchant_delivery
  final String fulfillmentType;

  const CheckoutParams({
    required this.storeId,
    required this.productId,
    required this.quantity,
    required this.productTotal,
    this.notes,
    required this.deliveryAddress,
    this.deliveryLat,
    this.deliveryLng,
    required this.paymentMethod,
    this.walletReceiptPath,
    this.fulfillmentType = 'pending',
  });

  bool get isPickup => fulfillmentType == 'pickup';

  @override
  List<Object?> get props => [
        storeId,
        productId,
        quantity,
        productTotal,
        notes,
        deliveryAddress,
        deliveryLat,
        deliveryLng,
        paymentMethod,
        walletReceiptPath,
        fulfillmentType,
      ];
}

class ServiceOrder extends Equatable {
  final int id;
  final String status;
  final String message;

  const ServiceOrder({
    required this.id,
    required this.status,
    required this.message,
  });

  @override
  List<Object?> get props => [id, status, message];
}

class SubmitCustomOrderParams extends Equatable {
  final int storeId;
  final String? requestText;
  final String? requestImagePath;
  final String deliveryAddress;
  final double? deliveryLat;
  final double? deliveryLng;
  final String contactPhone;
  final String? notes;

  const SubmitCustomOrderParams({
    required this.storeId,
    this.requestText,
    this.requestImagePath,
    required this.deliveryAddress,
    this.deliveryLat,
    this.deliveryLng,
    required this.contactPhone,
    this.notes,
  });

  bool get hasText => (requestText ?? '').trim().isNotEmpty;
  bool get hasImage =>
      requestImagePath != null && requestImagePath!.trim().isNotEmpty;
  bool get hasRequestContent => hasText || hasImage;

  @override
  List<Object?> get props => [
        storeId,
        requestText,
        requestImagePath,
        deliveryAddress,
        deliveryLat,
        deliveryLng,
        contactPhone,
        notes,
      ];
}

/// Client-facing custom order (الطلب المخصص).
class CustomOrder extends Equatable {
  final int id;
  final String orderType;
  final int? storeId;
  final String? storeName;
  final String? requestText;
  final String? requestImage;
  final String deliveryAddress;
  final String? contactPhone;
  final String? notes;
  final double? offerPrice;
  final String? offerNotes;
  final String status;
  final String statusLabel;
  final bool canAcceptOffer;
  final bool canRejectOffer;
  final String? message;

  const CustomOrder({
    required this.id,
    this.orderType = 'custom',
    this.storeId,
    this.storeName,
    this.requestText,
    this.requestImage,
    this.deliveryAddress = '',
    this.contactPhone,
    this.notes,
    this.offerPrice,
    this.offerNotes,
    required this.status,
    this.statusLabel = '',
    this.canAcceptOffer = false,
    this.canRejectOffer = false,
    this.message,
  });

  bool get isCustom => orderType == 'custom';
  bool get needsOfferAction => canAcceptOffer || canRejectOffer;

  @override
  List<Object?> get props => [
        id,
        orderType,
        status,
        offerPrice,
        canAcceptOffer,
        canRejectOffer,
      ];
}
