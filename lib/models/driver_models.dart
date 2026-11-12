class DriverOrderItem {
  final int id;
  final String type;
  final String title;
  final String? pickLoc;
  final String? targetLoc;
  final String? distanceLabel;
  final String? description;
  final String? status;
  final bool canOffer;
  final double? myOfferAmount;
  final String? offerStatus;
  final bool showContact;
  final String? customerName;
  final String? customerPhone;
  final int? customerId;
  final double customerRating;
  final int customerRatingsCount;
  final int? rideBookId;
  final double? amount;
  final double? deliveryFee;
  final String? paymentMethodLabel;
  final String? createdAt;
  final bool canAcceptInvitation;
  final double? orderTotal;

  DriverOrderItem({
    required this.id,
    required this.type,
    required this.title,
    this.pickLoc,
    this.targetLoc,
    this.distanceLabel,
    this.description,
    this.status,
    this.canOffer = false,
    this.myOfferAmount,
    this.offerStatus,
    this.showContact = false,
    this.customerName,
    this.customerPhone,
    this.customerId,
    this.customerRating = 0,
    this.customerRatingsCount = 0,
    this.rideBookId,
    this.amount,
    this.deliveryFee,
    this.paymentMethodLabel,
    this.createdAt,
    this.canAcceptInvitation = false,
    this.orderTotal,
  });

  factory DriverOrderItem.fromJson(Map<String, dynamic> json) {
    return DriverOrderItem(
      id: json['id'] as int? ?? 0,
      type: json['type']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      pickLoc: json['pick_loc']?.toString(),
      targetLoc: json['target_loc']?.toString(),
      distanceLabel: json['distance_label']?.toString(),
      description: json['description']?.toString(),
      status: json['status']?.toString(),
      canOffer: json['can_offer'] == true,
      myOfferAmount: double.tryParse(json['my_offer_amount']?.toString() ?? ''),
      offerStatus: json['offer_status']?.toString(),
      showContact: json['show_contact'] == true,
      customerName: json['customer_name']?.toString(),
      customerPhone: json['customer_phone']?.toString(),
      customerId: json['customer_id'] as int? ??
          int.tryParse('${json['user_id'] ?? ''}'),
      customerRating: double.tryParse(
            (json['customer_rating'] ?? json['avg_rating'])?.toString() ?? '',
          ) ??
          0,
      customerRatingsCount:
          int.tryParse('${json['customer_ratings_count'] ?? 0}') ?? 0,
      rideBookId: json['ride_book_id'] as int?,
      amount: double.tryParse(json['amount']?.toString() ?? ''),
      deliveryFee: double.tryParse(json['delivery_fee']?.toString() ?? ''),
      paymentMethodLabel: json['payment_method_label']?.toString(),
      createdAt: json['created_at']?.toString(),
      canAcceptInvitation: json['can_accept_invitation'] == true,
      orderTotal: double.tryParse(json['order_total']?.toString() ?? ''),
    );
  }

  bool get isActive =>
      showContact ||
      canAcceptInvitation ||
      status == 'in_progress' ||
      status == 'accepted' ||
      status == 'driver_assigned' ||
      status == 'in_delivery';
}

class DriverCompletedOrder {
  final int id;
  final String type;
  final String? pickLoc;
  final String? targetLoc;
  final String? description;
  final double? amount;
  final String? completedAt;

  DriverCompletedOrder({
    required this.id,
    required this.type,
    this.pickLoc,
    this.targetLoc,
    this.description,
    this.amount,
    this.completedAt,
  });

  factory DriverCompletedOrder.fromJson(Map<String, dynamic> json) {
    return DriverCompletedOrder(
      id: json['id'] as int? ?? 0,
      type: json['type']?.toString() ?? '',
      pickLoc: json['pick_loc']?.toString(),
      targetLoc: json['target_loc']?.toString(),
      description: json['description']?.toString(),
      amount: double.tryParse(json['amount']?.toString() ?? ''),
      completedAt: json['completed_at']?.toString(),
    );
  }
}

class DriverDuesSummary {
  final double duesBalance;
  final double commissionRate;
  final int completedOrdersCount;
  final String walletNumber;
  final String instapayNumber;

  DriverDuesSummary({
    required this.duesBalance,
    required this.commissionRate,
    required this.completedOrdersCount,
    required this.walletNumber,
    required this.instapayNumber,
  });

  factory DriverDuesSummary.fromJson(Map<String, dynamic> json) {
    return DriverDuesSummary(
      duesBalance: double.tryParse(json['dues_balance']?.toString() ?? '') ?? 0,
      commissionRate:
          double.tryParse(json['commission_rate']?.toString() ?? '') ?? 10,
      completedOrdersCount: json['completed_orders_count'] as int? ?? 0,
      walletNumber: json['wallet_number']?.toString() ?? '',
      instapayNumber: json['instapay_number']?.toString() ?? '',
    );
  }
}
