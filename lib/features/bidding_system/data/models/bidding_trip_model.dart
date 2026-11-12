import 'package:motorent/features/bidding_system/domain/entities/bidding_driver.dart';
import 'package:motorent/features/bidding_system/domain/entities/bidding_offer.dart';
import 'package:motorent/features/bidding_system/data/models/bidding_offer_model.dart';
import 'package:motorent/features/bidding_system/domain/entities/bidding_trip.dart';

class BiddingTripModel extends BiddingTrip {
  const BiddingTripModel({
    required super.id,
    required super.userId,
    required super.vehicleType,
    required super.pickupAddress,
    super.pickupLat,
    super.pickupLng,
    required super.dropoffAddress,
    super.dropoffLat,
    super.dropoffLng,
    required super.description,
    required super.phone,
    super.notes,
    required super.status,
    super.customerPrice,
    super.finalPrice,
    super.acceptedOfferId,
    super.acceptedOffer,
    super.driver,
    super.createdAt,
  });

  factory BiddingTripModel.fromJson(Map<String, dynamic> json) {
    BiddingOffer? acceptedOffer;
    final acceptedRaw = json['accepted_offer'] ?? json['driver_offer'];
    if (acceptedRaw is Map) {
      acceptedOffer = BiddingOfferModel.fromJson(
        Map<String, dynamic>.from(acceptedRaw),
      );
    }

    BiddingDriver? driver = _parseDriver(json['driver']);
    if (driver == null && acceptedOffer != null) {
      driver = BiddingDriver(
        id: acceptedOffer.driverId,
        name: acceptedOffer.driverName,
        image: acceptedOffer.driverImage,
        phone: acceptedOffer.driverPhone,
        rating: acceptedOffer.rating,
      );
    }
    final extraPhone = (json['driver_phone'] ?? json['driverPhone'] ?? '')
        .toString()
        .trim();
    if (driver != null &&
        (driver.phone == null || driver.phone!.trim().isEmpty) &&
        extraPhone.isNotEmpty) {
      driver = BiddingDriver(
        id: driver.id,
        name: driver.name,
        image: driver.image,
        phone: extraPhone,
        rating: driver.rating,
      );
    }

    return BiddingTripModel(
      id: _asInt(json['id']),
      userId: _asInt(json['user_id'] ?? json['customer_id']),
      vehicleType: (json['vehicle_type'] ?? '').toString(),
      pickupAddress: (json['pickup_address'] ??
              json['pick_loc'] ??
              json['pickup'] ??
              '')
          .toString(),
      pickupLat: _asDouble(json['pickup_lat'] ?? json['pick_lat']),
      pickupLng: _asDouble(json['pickup_lng'] ?? json['pick_lng']),
      dropoffAddress: (json['dropoff_address'] ??
              json['target_loc'] ??
              json['dropoff'] ??
              '')
          .toString(),
      dropoffLat: _asDouble(json['dropoff_lat'] ?? json['target_lat']),
      dropoffLng: _asDouble(json['dropoff_lng'] ?? json['target_lng']),
      description: (json['description'] ?? '').toString(),
      phone: (json['phone'] ?? json['contact_phone'] ?? '').toString(),
      notes: json['notes']?.toString(),
      status: _normalizeStatus((json['status'] ?? 'pending').toString()),
      customerPrice: _asDouble(
        json['customer_price'] ?? json['requested_price'] ?? json['offer_price'],
      ),
      finalPrice: _asDouble(
        json['final_price'] ?? json['accepted_price'] ?? json['agreed_price'],
      ),
      acceptedOfferId: json['accepted_offer_id'] != null
          ? _asInt(json['accepted_offer_id'])
          : null,
      acceptedOffer: acceptedOffer,
      driver: driver,
      createdAt: _asDate(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'vehicle_type': vehicleType,
      'pickup_address': pickupAddress,
      'pickup_lat': pickupLat,
      'pickup_lng': pickupLng,
      'dropoff_address': dropoffAddress,
      'dropoff_lat': dropoffLat,
      'dropoff_lng': dropoffLng,
      'description': description,
      'phone': phone,
      'notes': notes,
      'status': status,
      'customer_price': customerPrice,
      'final_price': finalPrice,
      'accepted_offer_id': acceptedOfferId,
      'created_at': createdAt?.toIso8601String(),
      if (acceptedOffer != null)
        'accepted_offer': BiddingOfferModel.fromEntity(acceptedOffer!).toJson(),
      if (driver != null)
        'driver': {
          'id': driver!.id,
          'name': driver!.name,
          'image': driver!.image,
          'phone': driver!.phone,
          'rating': driver!.rating,
        },
    };
  }

  static BiddingDriver? _parseDriver(dynamic raw) {
    if (raw is! Map) return null;
    final map = Map<String, dynamic>.from(raw);
    final name = (map['name'] ?? map['driver_name'] ?? '').toString().trim();
    if (name.isEmpty && map['id'] == null) return null;

    return BiddingDriver(
      id: _asInt(map['id'] ?? map['driver_id']),
      name: name.isEmpty ? 'سائق' : name,
      image: (map['image'] ?? map['driver_image'] ?? map['photo'])?.toString(),
      phone: (map['phone'] ?? map['driver_phone'] ?? map['mobile'])?.toString(),
      rating: _asDouble(
            map['avg_rating'] ?? map['rating'] ?? map['driver_rating'],
          ) ??
          0,
    );
  }

  static String _normalizeStatus(String raw) {
    switch (raw.toLowerCase()) {
      case 'awaiting_offers':
      case 'open':
      case 'pending':
        return 'pending';
      case 'accepted':
      case 'active':
      case 'in_progress':
        return 'in_progress';
      case 'completed':
      case 'done':
        return 'completed';
      case 'cancelled':
      case 'canceled':
        return 'cancelled';
      default:
        return raw;
    }
  }

  static int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static double? _asDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  static DateTime? _asDate(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }
}
