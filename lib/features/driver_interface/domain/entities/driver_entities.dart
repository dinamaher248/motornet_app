import 'package:equatable/equatable.dart';

class DriverTrip extends Equatable {
  final int id;
  final String type;
  final String title;
  final String? pickup;
  final String? dropoff;
  final double? pickupLat;
  final double? pickupLng;
  final double? dropoffLat;
  final double? dropoffLng;
  final String? distanceLabel;
  final String? routeDistanceLabel;
  final String? description;
  final String? status;
  final bool canOffer;
  final double? myOfferAmount;
  final String? offerStatus;
  final bool showContact;
  final String? customerName;
  final String? customerPhone;
  final double? customerRating;
  final int? customerRatingsCount;
  final int? customerId;
  final int? rideBookId;
  final double? amount;
  final double? customerPrice;
  final bool canAcceptInvitation;
  final String? createdAt;
  final String? completedAt;

  const DriverTrip({
    required this.id,
    required this.type,
    required this.title,
    this.pickup,
    this.dropoff,
    this.pickupLat,
    this.pickupLng,
    this.dropoffLat,
    this.dropoffLng,
    this.distanceLabel,
    this.routeDistanceLabel,
    this.description,
    this.status,
    this.canOffer = false,
    this.myOfferAmount,
    this.offerStatus,
    this.showContact = false,
    this.customerName,
    this.customerPhone,
    this.customerRating,
    this.customerRatingsCount,
    this.customerId,
    this.rideBookId,
    this.amount,
    this.customerPrice,
    this.canAcceptInvitation = false,
    this.createdAt,
    this.completedAt,
  });

  bool get isAccepted =>
      showContact ||
      status == 'accepted' ||
      status == 'in_progress' ||
      status == 'handed_to_driver' ||
      status == 'driver_assigned' ||
      status == 'in_delivery' ||
      offerStatus == 'accepted';

  DriverTrip copyWith({
    int? id,
    String? type,
    String? title,
    String? pickup,
    String? dropoff,
    double? pickupLat,
    double? pickupLng,
    double? dropoffLat,
    double? dropoffLng,
    String? distanceLabel,
    String? routeDistanceLabel,
    String? description,
    String? status,
    bool? canOffer,
    double? myOfferAmount,
    String? offerStatus,
    bool? showContact,
    String? customerName,
    String? customerPhone,
    double? customerRating,
    int? customerRatingsCount,
    int? customerId,
    int? rideBookId,
    double? amount,
    double? customerPrice,
    bool? canAcceptInvitation,
    String? createdAt,
    String? completedAt,
  }) {
    return DriverTrip(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      pickup: pickup ?? this.pickup,
      dropoff: dropoff ?? this.dropoff,
      pickupLat: pickupLat ?? this.pickupLat,
      pickupLng: pickupLng ?? this.pickupLng,
      dropoffLat: dropoffLat ?? this.dropoffLat,
      dropoffLng: dropoffLng ?? this.dropoffLng,
      distanceLabel: distanceLabel ?? this.distanceLabel,
      routeDistanceLabel: routeDistanceLabel ?? this.routeDistanceLabel,
      description: description ?? this.description,
      status: status ?? this.status,
      canOffer: canOffer ?? this.canOffer,
      myOfferAmount: myOfferAmount ?? this.myOfferAmount,
      offerStatus: offerStatus ?? this.offerStatus,
      showContact: showContact ?? this.showContact,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      customerRating: customerRating ?? this.customerRating,
      customerRatingsCount: customerRatingsCount ?? this.customerRatingsCount,
      customerId: customerId ?? this.customerId,
      rideBookId: rideBookId ?? this.rideBookId,
      amount: amount ?? this.amount,
      customerPrice: customerPrice ?? this.customerPrice,
      canAcceptInvitation: canAcceptInvitation ?? this.canAcceptInvitation,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        type,
        title,
        pickup,
        dropoff,
        canOffer,
        showContact,
        myOfferAmount,
        customerPrice,
        status,
      ];
}

class DriverWallet extends Equatable {
  final double dueAmount;
  final double commissionRate;
  final int completedTripsCount;
  final String walletNumber;
  final String instapayNumber;
  final String billingMode;
  final bool commissionOptionEnabled;
  final bool fixedFeeOptionEnabled;
  final double orderFixedFee;

  const DriverWallet({
    required this.dueAmount,
    required this.commissionRate,
    required this.completedTripsCount,
    required this.walletNumber,
    required this.instapayNumber,
    this.billingMode = 'commission',
    this.commissionOptionEnabled = true,
    this.fixedFeeOptionEnabled = false,
    this.orderFixedFee = 10,
  });

  bool get isFixedFeeMode => billingMode == 'fixed_fee';

  String get rateLabel => isFixedFeeMode
      ? '${orderFixedFee.toStringAsFixed(0)} ج.م / طلب'
      : '${commissionRate.toStringAsFixed(0)}%';

  String get displayWallet =>
      walletNumber.isNotEmpty ? walletNumber : instapayNumber;

  @override
  List<Object?> get props => [
        dueAmount,
        commissionRate,
        completedTripsCount,
        walletNumber,
        instapayNumber,
        billingMode,
        commissionOptionEnabled,
        fixedFeeOptionEnabled,
        orderFixedFee,
      ];
}
