import 'package:motorent/features/bidding_system/domain/entities/bidding_offer.dart';

class BiddingOfferModel extends BiddingOffer {
  const BiddingOfferModel({
    required super.id,
    required super.tripId,
    required super.driverId,
    required super.driverName,
    super.driverImage,
    required super.rating,
    required super.proposedPrice,
    required super.status,
    super.driverPhone,
    super.distanceLabel,
    super.createdAt,
  });

  factory BiddingOfferModel.fromEntity(BiddingOffer offer) {
    return BiddingOfferModel(
      id: offer.id,
      tripId: offer.tripId,
      driverId: offer.driverId,
      driverName: offer.driverName,
      driverImage: offer.driverImage,
      rating: offer.rating,
      proposedPrice: offer.proposedPrice,
      status: offer.status,
      driverPhone: offer.driverPhone,
      distanceLabel: offer.distanceLabel,
      createdAt: offer.createdAt,
    );
  }

  factory BiddingOfferModel.fromJson(Map<String, dynamic> json) {
    final driver = json['driver'];
    Map<String, dynamic>? driverMap;
    if (driver is Map) {
      driverMap = Map<String, dynamic>.from(driver);
    }

    return BiddingOfferModel(
      id: _asInt(json['id']),
      tripId: _asInt(json['trip_id'] ?? json['bidding_trip_id']),
      driverId: _asInt(
        json['driver_id'] ?? driverMap?['id'] ?? 0,
      ),
      driverName: (json['driver_name'] ??
              driverMap?['name'] ??
              json['name'] ??
              'سائق')
          .toString(),
      driverImage: (json['driver_image'] ??
              driverMap?['image'] ??
              json['image'])
          ?.toString(),
      rating: _asDouble(
            json['avg_rating'] ??
                json['rating'] ??
                json['driver_rating'] ??
                driverMap?['avg_rating'] ??
                driverMap?['rating'] ??
                0,
          ) ??
          0,
      proposedPrice: _asDouble(
            json['proposed_price'] ??
                json['amount'] ??
                json['price'] ??
                0,
          ) ??
          0,
      status: (json['status'] ?? 'pending').toString(),
      driverPhone: (json['driver_phone'] ??
              driverMap?['phone'] ??
              json['phone'])
          ?.toString(),
      distanceLabel: (json['distance_label'] ??
              driverMap?['distance_label'] ??
              json['distanceLabel'])
          ?.toString(),
      createdAt: _asDate(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'trip_id': tripId,
      'driver_id': driverId,
      'driver_name': driverName,
      'driver_image': driverImage,
      'rating': rating,
      'proposed_price': proposedPrice,
      'status': status,
      'driver_phone': driverPhone,
      'distance_label': distanceLabel,
      'created_at': createdAt?.toIso8601String(),
    };
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
