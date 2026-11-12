class HomeResponse {
  final int? statusCode;
  final String? role;
  final HomeProfile? profile;
  final HomeData? data;

  HomeResponse({
    this.statusCode,
    this.role,
    this.profile,
    this.data,
  });

  factory HomeResponse.fromJson(Map<String, dynamic> json) {
    return HomeResponse(
      statusCode: _asIntOrNull(json['status_code']),
      role: json['role']?.toString(),
      profile: json['profile'] != null
          ? HomeProfile.fromJson(json['profile'] as Map<String, dynamic>)
          : null,
      data: json['data'] != null
          ? HomeData.fromJson(json['data'] as Map<String, dynamic>)
          : null,
    );
  }
}

// بيانات الـ profile
class HomeProfile {
  final int? id;
  final String? name;
  final String? username;
  final String? phone;
  final String? email;
  final String? title;         // user / driver
  final String? governorate;
  final String? area;
  final String? vehicleType;
  final int? coins;
  final bool isOnline;

  // خاصة بالسائق (driver) – ممكن تكون null في حالة user
  final String? subscriptionStatus;
  final HomeActiveSubscription? activeSubscription;

  HomeProfile({
    this.id,
    this.name,
    this.username,
    this.phone,
    this.email,
    this.title,
    this.governorate,
    this.area,
    this.vehicleType,
    this.coins,
    this.isOnline = false,
    this.subscriptionStatus,
    this.activeSubscription,
  });

  factory HomeProfile.fromJson(Map<String, dynamic> json) {
    return HomeProfile(
      id: json['id'] as int?,
      name: json['name'] as String?,
      username: json['username'] as String?,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      title: json['title'] as String?,
      governorate: json['governorate'] as String?,
      area: json['area'] as String?,
      vehicleType: json['vehicle_type'] as String?,
      coins: json['coins'] is int ? json['coins'] as int? : null,
      isOnline: _parseBool(json['is_online']),
      subscriptionStatus: json['subscription_status'] as String?,
      activeSubscription: json['active_subscription'] != null
          ? HomeActiveSubscription.fromJson(
          json['active_subscription'] as Map<String, dynamic>)
          : null,
    );
  }
}

class HomeActiveSubscription {
  final int? planId;
  final String? planName;
  final String? startDate;
  final String? endDate;

  HomeActiveSubscription({
    this.planId,
    this.planName,
    this.startDate,
    this.endDate,
  });

  factory HomeActiveSubscription.fromJson(Map<String, dynamic> json) {
    return HomeActiveSubscription(
      planId: json['plan_id'] as int?,
      planName: json['plan_name'] as String?,
      startDate: json['start_date'] as String?,
      endDate: json['end_date'] as String?,
    );
  }
}

// جزء data: بيخدم الحالتين (user / driver)
class HomeData {
  final List<HomeDriver> drivers;
  final List<HomeOrder> orders;

  // للسائق فقط – ممكن تكون فاضية مع user
  final List<HomeBookingRequest> bookingRequests;
  final HomeStats? stats;

  HomeData({
    this.drivers = const [],
    this.orders = const [],
    this.bookingRequests = const [],
    this.stats,
  });

  factory HomeData.fromJson(Map<String, dynamic> json) {
    final rawOrders = (json['active_orders'] as List<dynamic>?) ??
        (json['orders'] as List<dynamic>?);
    return HomeData(
      drivers: (json['drivers'] as List<dynamic>?)
          ?.map((e) => HomeDriver.fromJson(e as Map<String, dynamic>))
          .toList() ??
          const [],
      orders: rawOrders
              ?.map((e) => HomeOrder.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      bookingRequests: (json['booking_requests'] as List<dynamic>?)
          ?.map((e) => HomeBookingRequest.fromJson(
              e as Map<String, dynamic>))
          .toList() ??
          const [],
      stats: json['stats'] != null
          ? HomeStats.fromJson(json['stats'] as Map<String, dynamic>)
          : null,
    );
  }
}

// driver داخل data.drivers
class HomeDriver {
  final int? id;
  final String? name;
  final String? phone;
  final String? vehicleType;
  final String? governorate;
  final String? area;
  final bool isOnline;
  final bool isBooked;

  HomeDriver({
    this.id,
    this.name,
    this.phone,
    this.vehicleType,
    this.governorate,
    this.area,
    this.isOnline = false,
    this.isBooked = false,
  });

  factory HomeDriver.fromJson(Map<String, dynamic> json) {
    return HomeDriver(
      id: json['id'] as int?,
      name: json['name'] as String?,
      phone: json['phone'] as String?,
      vehicleType: json['vehicle_type'] as String?,
      governorate: json['governorate'] as String?,
      area: json['area'] as String?,
      isOnline: _parseBool(json['is_online']),
      isBooked: _parseBool(json['is_booked']),
    );
  }
}

// order داخل data.orders
class HomeOrder {
  final int? id;
  final String? type;
  final String? title;
  final double? amount;
  final String? msg;
  final String? pickLoc;
  final String? targetLoc;
  final String? status;
  final String? statusLabel;
  final bool isActive;
  final String? createdAt;
  final HomeOrderDriver? driver;

  HomeOrder({
    this.id,
    this.type,
    this.title,
    this.amount,
    this.msg,
    this.pickLoc,
    this.targetLoc,
    this.status,
    this.statusLabel,
    this.isActive = true,
    this.createdAt,
    this.driver,
  });

  bool get isPendingBidding =>
      (type == 'bidding_trip' || type == null) &&
      (status == 'pending' || status == 'awaiting_offers');

  bool get canTrack =>
      !isPendingBidding &&
      type != 'ride_book' &&
      (type == 'bidding_trip' ||
          type == 'service_order' ||
          type == 'custom_order');

  factory HomeOrder.fromJson(Map<String, dynamic> json) {
    return HomeOrder(
      id: _asIntOrNull(json['id']),
      type: (json['type'] ?? 'bidding_trip')?.toString(),
      title: json['title']?.toString(),
      amount: _asDouble(json['amount']),
      msg: json['msg']?.toString(),
      pickLoc: (json['pick_loc'] ?? json['pickup_address'])?.toString(),
      targetLoc: (json['target_loc'] ?? json['dropoff_address'])?.toString(),
      status: json['status']?.toString(),
      statusLabel: (json['status_label'] ?? json['statusLabel'])?.toString(),
      isActive: json['is_active'] != false,
      createdAt: json['created_at']?.toString(),
      driver: json['driver'] != null
          ? HomeOrderDriver.fromJson(json['driver'] as Map<String, dynamic>)
          : null,
    );
  }
}

int? _asIntOrNull(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse(v.toString());
}

double? _asDouble(dynamic v) {
  if (v == null) return null;
  if (v is double) return v;
  if (v is int) return v.toDouble();
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString());
}

class HomeOrderDriver {
  final int? id;
  final String? name;
  final String? phone;
  final String? vehicleType;

  HomeOrderDriver({
    this.id,
    this.name,
    this.phone,
    this.vehicleType,
  });

  factory HomeOrderDriver.fromJson(Map<String, dynamic> json) {
    return HomeOrderDriver(
      id: _asIntOrNull(json['id']),
      name: json['name']?.toString(),
      phone: json['phone']?.toString(),
      vehicleType: json['vehicle_type']?.toString(),
    );
  }
}

// شكل booking_requests المتوقع للسائق
class HomeBookingRequest {
  final int? id;
  final int? customerId;
  final String? customerName;
  final String? customerPhone;
  final int? seatCount;
  final int? amount;
  final String? msg;
  final String? pickLoc;
  final String? targetLoc;
  final String? status;
  final String? createdAt;

  HomeBookingRequest({
    this.id,
    this.customerId,
    this.customerName,
    this.customerPhone,
    this.seatCount,
    this.amount,
    this.msg,
    this.pickLoc,
    this.targetLoc,
    this.status,
    this.createdAt,
  });

  factory HomeBookingRequest.fromJson(Map<String, dynamic> json) {
    return HomeBookingRequest(
      id: json['id'] as int?,
      customerId: json['customer_id'] as int?,
      customerName: json['customer_name'] as String?,
      customerPhone: json['customer_phone'] as String?,
      seatCount: json['seat_count'] as int?,
      amount: json['amount'] as int?,
      msg: json['msg'] as String?,
      pickLoc: json['pick_loc'] as String?,
      targetLoc: json['target_loc'] as String?,
      status: json['status'] as String?,
      createdAt: json['created_at'] as String?,
    );
  }
}

class HomeStats {
  final int? acceptedCount;
  final int? refusedCount;

  HomeStats({this.acceptedCount, this.refusedCount});

  factory HomeStats.fromJson(Map<String, dynamic> json) {
    return HomeStats(
      acceptedCount: json['acceptedCount'] as int?,
      refusedCount: json['refusedCount'] as int?,
    );
  }
}

// helper صغير للتعامل مع 0/1 أو true/false
bool _parseBool(dynamic value) {
  if (value is bool) return value;
  if (value is int) return value == 1;
  if (value is String) {
    return value == '1' || value.toLowerCase() == 'true';
  }
  return false;
}
