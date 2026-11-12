import 'package:equatable/equatable.dart';

/// Payload used when creating a bidding trip.
class CreateBiddingTripParams extends Equatable {
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
  final double customerPrice;

  const CreateBiddingTripParams({
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
    required this.customerPrice,
  });

  Map<String, dynamic> toJson() {
    return {
      'vehicle_type': vehicleType,
      'pickup_address': pickupAddress,
      if (pickupLat != null) 'pickup_lat': pickupLat,
      if (pickupLng != null) 'pickup_lng': pickupLng,
      'dropoff_address': dropoffAddress,
      if (dropoffLat != null) 'dropoff_lat': dropoffLat,
      if (dropoffLng != null) 'dropoff_lng': dropoffLng,
      'description': description,
      'phone': phone,
      if (notes != null && notes!.trim().isNotEmpty) 'notes': notes!.trim(),
      'customer_price': customerPrice,
      'requested_price': customerPrice,
      'price': customerPrice,
    };
  }

  @override
  List<Object?> get props => [
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
        customerPrice,
      ];
}
