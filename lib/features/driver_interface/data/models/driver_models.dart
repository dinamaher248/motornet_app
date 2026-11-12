import 'package:motorent/features/driver_interface/domain/entities/driver_entities.dart';

class DriverTripModel extends DriverTrip {
  const DriverTripModel({
    required super.id,
    required super.type,
    required super.title,
    super.pickup,
    super.dropoff,
    super.pickupLat,
    super.pickupLng,
    super.dropoffLat,
    super.dropoffLng,
    super.distanceLabel,
    super.routeDistanceLabel,
    super.description,
    super.status,
    super.canOffer,
    super.myOfferAmount,
    super.offerStatus,
    super.showContact,
    super.customerName,
    super.customerPhone,
    super.customerRating,
    super.customerRatingsCount,
    super.customerId,
    super.rideBookId,
    super.amount,
    super.customerPrice,
    super.canAcceptInvitation,
    super.createdAt,
    super.completedAt,
  });

  factory DriverTripModel.fromJson(Map<String, dynamic> json) {
    return DriverTripModel(
      id: _asInt(json['id']),
      type: (json['type'] ?? 'trip_request').toString(),
      title: (json['title'] ?? 'طلب').toString(),
      pickup: (json['pick_loc'] ?? json['pickup'] ?? json['pickup_address'])
          ?.toString(),
      dropoff: (json['target_loc'] ??
              json['dropoff'] ??
              json['dropoff_address'])
          ?.toString(),
      pickupLat: _asDouble(json['pick_lat'] ?? json['pickup_lat']),
      pickupLng: _asDouble(json['pick_lng'] ?? json['pickup_lng']),
      dropoffLat: _asDouble(json['target_lat'] ?? json['dropoff_lat']),
      dropoffLng: _asDouble(json['target_lng'] ?? json['dropoff_lng']),
      distanceLabel:
          (json['distance_label'] ?? json['distanceLabel'])?.toString(),
      routeDistanceLabel: (json['route_distance_label'] ??
              json['routeDistanceLabel'])
          ?.toString(),
      description: json['description']?.toString(),
      status: json['status']?.toString(),
      canOffer: json['can_offer'] == true || json['canOffer'] == true,
      myOfferAmount: _asDouble(json['my_offer_amount'] ?? json['myOfferAmount']),
      offerStatus: (json['offer_status'] ?? json['offerStatus'])?.toString(),
      showContact: json['show_contact'] == true || json['showContact'] == true,
      customerName: (json['customer_name'] ?? json['customerName'])?.toString(),
      customerPhone:
          (json['customer_phone'] ?? json['customerPhone'])?.toString(),
      customerRating: _asDouble(
        json['customer_rating'] ?? json['customerRating'],
      ),
      customerRatingsCount: _asIntOrNull(
        json['customer_ratings_count'] ?? json['customerRatingsCount'],
      ),
      customerId: _asIntOrNull(json['customer_id'] ?? json['customerId']),
      rideBookId: _asIntOrNull(json['ride_book_id'] ?? json['rideBookId']),
      amount: _asDouble(json['amount'] ?? json['delivery_fee']),
      customerPrice: _asDouble(
        json['customer_price'] ?? json['requested_price'] ?? json['amount'],
      ),
      canAcceptInvitation: json['can_accept_invitation'] == true,
      createdAt: json['created_at']?.toString(),
      completedAt: json['completed_at']?.toString(),
    );
  }

  static int _asInt(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v?.toString() ?? '') ?? 0;
  }

  static int? _asIntOrNull(dynamic v) {
    if (v == null) return null;
    final n = _asInt(v);
    return n == 0 && v.toString() != '0' ? null : n;
  }

  static double? _asDouble(dynamic v) {
    if (v == null) return null;
    if (v is double) return v;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }
}

class DriverWalletModel extends DriverWallet {
  const DriverWalletModel({
    required super.dueAmount,
    required super.commissionRate,
    required super.completedTripsCount,
    required super.walletNumber,
    required super.instapayNumber,
    super.billingMode,
    super.commissionOptionEnabled,
    super.fixedFeeOptionEnabled,
    super.orderFixedFee,
  });

  factory DriverWalletModel.fromJson(Map<String, dynamic> json) {
    double? parseRate(dynamic v) {
      if (v == null) return null;
      if (v is num) return v.toDouble();
      final s = v.toString().replaceAll('%', '').trim();
      return double.tryParse(s);
    }

    bool flag(dynamic v, {required bool fallback}) {
      if (v == null) return fallback;
      if (v == true || v == 1) return true;
      if (v == false || v == 0) return false;
      final s = v.toString().trim().toLowerCase();
      if (s.isEmpty) return fallback;
      return s == '1' || s == 'true' || s == 'yes' || s == 'on';
    }

    return DriverWalletModel(
      dueAmount: _asDouble(
            json['due_amount'] ??
                json['dues_balance'] ??
                json['dueAmount'],
          ) ??
          0,
      commissionRate: parseRate(
            json['commission_rate'] ??
                json['commission_percent'] ??
                json['order_commission_percent'] ??
                json['commissionRate'],
          ) ??
          10,
      completedTripsCount: DriverTripModel._asInt(
        json['completed_trips_count'] ??
            json['completed_trips'] ??
            json['completed_orders_count'] ??
            json['completedTripsCount'],
      ),
      walletNumber: (json['wallet_number'] ??
              json['app_wallet_number'] ??
              json['vodafone_cash_number'] ??
              json['walletNumber'] ??
              '')
          .toString(),
      instapayNumber: (json['instapay_number'] ??
              json['instapay_handle'] ??
              json['instapayNumber'] ??
              '')
          .toString(),
      billingMode: (json['billing_mode'] ?? 'commission').toString(),
      commissionOptionEnabled:
          flag(json['commission_option_enabled'], fallback: true),
      fixedFeeOptionEnabled:
          flag(json['fixed_fee_option_enabled'], fallback: false),
      orderFixedFee: _asDouble(
            json['order_fixed_fee'] ?? json['fixed_fee_per_order'],
          ) ??
          10,
    );
  }

  static double? _asDouble(dynamic v) {
    if (v == null) return null;
    if (v is double) return v;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }
}
