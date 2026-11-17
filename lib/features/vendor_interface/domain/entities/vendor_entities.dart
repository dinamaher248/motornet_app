import 'package:equatable/equatable.dart';

class VendorCategory extends Equatable {
  final int id;
  final String slug;
  final String name;
  /// orders | bookings | services
  final String hubSection;

  const VendorCategory({
    required this.id,
    required this.slug,
    required this.name,
    this.hubSection = 'orders',
  });

  @override
  List<Object?> get props => [id, slug, name, hubSection];
}

class VendorWorkingHours extends Equatable {
  final String dayKey;
  final String label;
  final String open;
  final String close;
  final bool isClosed;

  const VendorWorkingHours({
    required this.dayKey,
    required this.label,
    required this.open,
    required this.close,
    this.isClosed = false,
  });

  Map<String, dynamic> toJson() => {
        'day_key': dayKey,
        'label': label,
        'open': open,
        'close': close,
        'is_closed': isClosed,
      };

  static List<VendorWorkingHours> defaults() => const [
        VendorWorkingHours(
            dayKey: 'saturday', label: 'السبت', open: '09:00', close: '22:00'),
        VendorWorkingHours(
            dayKey: 'sunday', label: 'الأحد', open: '09:00', close: '22:00'),
        VendorWorkingHours(
            dayKey: 'monday', label: 'الاثنين', open: '09:00', close: '22:00'),
        VendorWorkingHours(
            dayKey: 'tuesday', label: 'الثلاثاء', open: '09:00', close: '22:00'),
        VendorWorkingHours(
            dayKey: 'wednesday',
            label: 'الأربعاء',
            open: '09:00',
            close: '22:00'),
        VendorWorkingHours(
            dayKey: 'thursday', label: 'الخميس', open: '09:00', close: '22:00'),
        VendorWorkingHours(
            dayKey: 'friday',
            label: 'الجمعة',
            open: '09:00',
            close: '22:00',
            isClosed: true),
      ];

  @override
  List<Object?> get props => [dayKey, label, open, close, isClosed];
}

class VendorStore extends Equatable {
  final int? id;
  final int? categoryId;
  final String name;
  final String? image;
  final String address;
  final String phone;
  final double? lat;
  final double? lng;
  final List<VendorWorkingHours> workingHours;
  final bool payOnDelivery;
  final bool payWallet;
  final String? walletNumber;
  final String? walletOwnerName;
  final String? walletType;
  final String listingKind;
  final List<VendorCategory> categories;

  const VendorStore({
    this.id,
    this.categoryId,
    this.name = '',
    this.image,
    this.address = '',
    this.phone = '',
    this.lat,
    this.lng,
    this.workingHours = const [],
    this.payOnDelivery = true,
    this.payWallet = false,
    this.walletNumber,
    this.walletOwnerName,
    this.walletType,
    this.listingKind = 'place',
    this.categories = const [],
  });

  @override
  List<Object?> get props => [
        id,
        categoryId,
        name,
        image,
        address,
        phone,
        lat,
        lng,
        payOnDelivery,
        payWallet,
        walletNumber,
      ];
}

class UpdateVendorStoreParams extends Equatable {
  final int categoryId;
  final String name;
  final String address;
  final String phone;
  final double lat;
  final double lng;
  final List<VendorWorkingHours> workingHours;
  final String? imagePath;
  final bool payOnDelivery;
  final bool payWallet;
  final String? walletNumber;
  final String? walletOwnerName;
  final String? walletType;
  final String listingKind;

  const UpdateVendorStoreParams({
    required this.categoryId,
    required this.name,
    required this.address,
    required this.phone,
    required this.lat,
    required this.lng,
    required this.workingHours,
    this.imagePath,
    required this.payOnDelivery,
    required this.payWallet,
    this.walletNumber,
    this.walletOwnerName,
    this.walletType,
    this.listingKind = 'place',
  });

  @override
  List<Object?> get props => [
        categoryId,
        name,
        address,
        phone,
        lat,
        lng,
        imagePath,
        payOnDelivery,
        payWallet,
        walletNumber,
      ];
}

class VendorProduct extends Equatable {
  final int id;
  final String name;
  final double price;
  final String? description;
  final String? image;
  final bool isActive;

  const VendorProduct({
    required this.id,
    required this.name,
    required this.price,
    this.description,
    this.image,
    this.isActive = true,
  });

  VendorProduct copyWith({
    String? name,
    double? price,
    String? description,
    String? image,
    bool? isActive,
  }) =>
      VendorProduct(
        id: id,
        name: name ?? this.name,
        price: price ?? this.price,
        description: description ?? this.description,
        image: image ?? this.image,
        isActive: isActive ?? this.isActive,
      );

  @override
  List<Object?> get props => [id, name, price, description, image, isActive];
}

class CreateVendorProductParams extends Equatable {
  final String name;
  final double price;

  /// اختيارية في «صور النشاط» (الحجوزات)، ومطلوبة في «المنتجات» (الطلبات).
  final String? imagePath;
  final String? description;

  const CreateVendorProductParams({
    required this.name,
    required this.price,
    this.imagePath,
    this.description,
  });

  @override
  List<Object?> get props => [name, price, imagePath, description];
}

class UpdateVendorProductParams extends Equatable {
  final int productId;
  final String name;
  final double price;
  final String? description;
  final String? imagePath;

  const UpdateVendorProductParams({
    required this.productId,
    required this.name,
    required this.price,
    this.description,
    this.imagePath,
  });

  @override
  List<Object?> get props =>
      [productId, name, price, description, imagePath];
}

class VendorOrder extends Equatable {
  final int id;
  final String productName;
  final double productPrice;
  final double totalPrice;
  final String? notes;
  final String customerName;
  final String? customerPhone;
  final String deliveryAddress;
  final String paymentMethod;
  final String paymentMethodLabel;
  final String? paymentProof;
  final String status;
  final String statusLabel;
  final bool canAccept;
  final bool canReject;
  final bool canConfirmPayment;
  final bool canRejectPayment;
  // Custom order fields
  final String orderType;
  final String? customRequestText;
  final String? customRequestImage;
  final double? offerPrice;
  final String? offerNotes;
  final bool canSendOffer;
  final bool revealCustomerContact;
  final double customerRating;
  final int customerRatingsCount;
  final bool canPrepareDispatch;
  final bool canViewDeliveryOffers;
  final bool canMarkCompleted;
  final String? vendorHint;
  final int? biddingTripId;
  final String fulfillmentType;
  final String fulfillmentLabel;
  final double? deliveryLat;
  final double? deliveryLng;
  final String? storeAddress;
  final double? storeLat;
  final double? storeLng;

  const VendorOrder({
    required this.id,
    required this.productName,
    required this.productPrice,
    required this.totalPrice,
    this.notes,
    required this.customerName,
    this.customerPhone,
    required this.deliveryAddress,
    required this.paymentMethod,
    required this.paymentMethodLabel,
    this.paymentProof,
    required this.status,
    required this.statusLabel,
    this.canAccept = false,
    this.canReject = false,
    this.canConfirmPayment = false,
    this.canRejectPayment = false,
    this.orderType = 'catalog',
    this.customRequestText,
    this.customRequestImage,
    this.offerPrice,
    this.offerNotes,
    this.canSendOffer = false,
    this.revealCustomerContact = false,
    this.customerRating = 0,
    this.customerRatingsCount = 0,
    this.canPrepareDispatch = false,
    this.canViewDeliveryOffers = false,
    this.canMarkCompleted = false,
    this.vendorHint,
    this.biddingTripId,
    this.fulfillmentType = 'pending',
    this.fulfillmentLabel = 'بانتظار اختيار العميل',
    this.deliveryLat,
    this.deliveryLng,
    this.storeAddress,
    this.storeLat,
    this.storeLng,
  });

  bool get isPickup => fulfillmentType == 'pickup';

  bool get isWallet =>
      paymentMethod == 'wallet' || paymentMethod == 'e_wallet';

  bool get needsPaymentReview => canConfirmPayment || canRejectPayment;

  bool get isCustom => orderType == 'custom';

  /// Pending custom orders awaiting a vendor offer — hide client identity.
  bool get isPendingCustomPricing =>
      isCustom && (canSendOffer || status == 'pending_offer' || status == 'pending');

  /// After client accepts a price offer — show name/phone + Call/Chat.
  bool get showCustomerIdentity {
    if (revealCustomerContact) return true;
    final s = status.toLowerCase();
    return s == 'accepted' ||
        s == 'merchant_accepted' ||
        s == 'in_progress' ||
        s == 'preparing' ||
        s == 'ready' ||
        s == 'assigned' ||
        s == 'on_the_way' ||
        s == 'delivered' ||
        s == 'completed' ||
        s == 'driver_assigned';
  }

  String get displayTitle {
    if (isCustom) {
      final text = (customRequestText ?? '').trim();
      if (text.isNotEmpty) return text;
      return 'طلب مخصص';
    }
    return productName;
  }

  @override
  List<Object?> get props => [
        id,
        productName,
        status,
        canAccept,
        canConfirmPayment,
        paymentProof,
        orderType,
        canSendOffer,
        customRequestText,
      ];
}

class SendCustomOfferParams extends Equatable {
  final int orderId;
  final double? totalPrice;
  final String? notes;

  const SendCustomOfferParams({
    required this.orderId,
    this.totalPrice,
    this.notes,
  });

  @override
  List<Object?> get props => [orderId, totalPrice, notes];
}

class VendorWallet extends Equatable {
  final double dueAmount;
  final double commissionRate;
  final int completedOrdersCount;
  final int bookingsCount;
  final String walletNumber;
  final String instapayNumber;
  final String billingMode;
  final String billingModeLabel;
  final String selectedBillingLabel;
  final bool commissionOptionEnabled;
  final bool fixedFeeOptionEnabled;
  final double orderCommissionPercent;
  final double orderFixedFee;
  final double debtLimit;
  final bool commissionEnabled;

  const VendorWallet({
    required this.dueAmount,
    required this.commissionRate,
    required this.completedOrdersCount,
    this.bookingsCount = 0,
    required this.walletNumber,
    required this.instapayNumber,
    this.billingMode = 'commission',
    this.billingModeLabel = '',
    this.selectedBillingLabel = '',
    this.commissionOptionEnabled = true,
    this.fixedFeeOptionEnabled = true,
    this.orderCommissionPercent = 5,
    this.orderFixedFee = 10,
    this.debtLimit = 0,
    this.commissionEnabled = true,
  });

  bool get isFixedFeeMode => billingMode == 'fixed_fee';

  String get billingSummaryLabel {
    if (selectedBillingLabel.isNotEmpty) return selectedBillingLabel;
    if (isFixedFeeMode) {
      return '${orderFixedFee.toStringAsFixed(0)} ج.م لكل طلب';
    }
    return '${orderCommissionPercent.toStringAsFixed(0)}% عمولة';
  }

  String get rateLabel => isFixedFeeMode
      ? '${orderFixedFee.toStringAsFixed(0)} ج.م / طلب'
      : '${orderCommissionPercent.toStringAsFixed(0)}%';

  String get displayWallet =>
      walletNumber.isNotEmpty ? walletNumber : instapayNumber;

  @override
  List<Object?> get props => [
        dueAmount,
        commissionRate,
        completedOrdersCount,
        bookingsCount,
        walletNumber,
        billingMode,
        selectedBillingLabel,
      ];
}
