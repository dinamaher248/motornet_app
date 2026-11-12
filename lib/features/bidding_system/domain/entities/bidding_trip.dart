import 'package:equatable/equatable.dart';
import 'package:motorent/features/bidding_system/domain/entities/bidding_driver.dart';
import 'package:motorent/features/bidding_system/domain/entities/bidding_offer.dart';

class BiddingTrip extends Equatable {
  final int id;
  final int userId;
  final String vehicleType;
  final String pickupAddress;
  final double? pickupLat;
  final double? pickupLng;
  final String dropoffAddress;
  final double? dropoffLat;
  final double? dropoffLng;
  final String description;
  final String phone;
  final String? notes;
  final String status;
  final double? customerPrice;
  final double? finalPrice;
  final int? acceptedOfferId;
  final BiddingOffer? acceptedOffer;
  final BiddingDriver? driver;
  final DateTime? createdAt;

  const BiddingTrip({
    required this.id,
    required this.userId,
    required this.vehicleType,
    required this.pickupAddress,
    this.pickupLat,
    this.pickupLng,
    required this.dropoffAddress,
    this.dropoffLat,
    this.dropoffLng,
    required this.description,
    required this.phone,
    this.notes,
    required this.status,
    this.customerPrice,
    this.finalPrice,
    this.acceptedOfferId,
    this.acceptedOffer,
    this.driver,
    this.createdAt,
  });

  bool get isPending =>
      status == 'pending' || status == 'awaiting_offers';

  bool get isInProgress =>
      status == 'in_progress' || status == 'handed_to_driver';

  bool get isCancelled => status == 'cancelled';

  bool get isCompleted => status == 'completed';

  String get statusLabelAr {
    switch (status) {
      case 'pending':
      case 'awaiting_offers':
        return 'قيد الانتظار';
      case 'in_progress':
        return 'جاري التنفيذ';
      case 'handed_to_driver':
        return 'جاري التوصيل';
      case 'completed':
        return 'مكتمل';
      case 'cancelled':
        return 'ملغي';
      default:
        return status;
    }
  }

  String get shortPickup {
    final value = pickupAddress.trim();
    if (value.length <= 42) return value;
    return '${value.substring(0, 42)}…';
  }

  String get shortDropoff {
    final value = dropoffAddress.trim();
    if (value.length <= 42) return value;
    return '${value.substring(0, 42)}…';
  }

  /// Prefer nested driver, then accepted offer driver fields.
  BiddingDriver? get resolvedDriver {
    if (driver != null) return driver;
    final offer = acceptedOffer;
    if (offer == null) return null;
    return BiddingDriver(
      id: offer.driverId,
      name: offer.driverName,
      image: offer.driverImage,
      phone: offer.driverPhone,
      rating: offer.rating,
    );
  }

  BiddingTrip copyWith({
    int? id,
    int? userId,
    String? vehicleType,
    String? pickupAddress,
    double? pickupLat,
    double? pickupLng,
    String? dropoffAddress,
    double? dropoffLat,
    double? dropoffLng,
    String? description,
    String? phone,
    String? notes,
    String? status,
    double? customerPrice,
    double? finalPrice,
    int? acceptedOfferId,
    BiddingOffer? acceptedOffer,
    BiddingDriver? driver,
    DateTime? createdAt,
  }) {
    return BiddingTrip(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      vehicleType: vehicleType ?? this.vehicleType,
      pickupAddress: pickupAddress ?? this.pickupAddress,
      pickupLat: pickupLat ?? this.pickupLat,
      pickupLng: pickupLng ?? this.pickupLng,
      dropoffAddress: dropoffAddress ?? this.dropoffAddress,
      dropoffLat: dropoffLat ?? this.dropoffLat,
      dropoffLng: dropoffLng ?? this.dropoffLng,
      description: description ?? this.description,
      phone: phone ?? this.phone,
      notes: notes ?? this.notes,
      status: status ?? this.status,
      customerPrice: customerPrice ?? this.customerPrice,
      finalPrice: finalPrice ?? this.finalPrice,
      acceptedOfferId: acceptedOfferId ?? this.acceptedOfferId,
      acceptedOffer: acceptedOffer ?? this.acceptedOffer,
      driver: driver ?? this.driver,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        vehicleType,
        pickupAddress,
        pickupLat,
        pickupLng,
        dropoffAddress,
        dropoffLat,
        dropoffLng,
        description,
        phone,
        notes,
        status,
        customerPrice,
        finalPrice,
        acceptedOfferId,
        acceptedOffer,
        driver,
        createdAt,
      ];
}
