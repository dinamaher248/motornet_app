import 'package:equatable/equatable.dart';

class BiddingOffer extends Equatable {
  final int id;
  final int tripId;
  final int driverId;
  final String driverName;
  final String? driverImage;
  final double rating;
  final double proposedPrice;
  final String status;
  final String? driverPhone;
  final String? distanceLabel;
  final DateTime? createdAt;

  const BiddingOffer({
    required this.id,
    required this.tripId,
    required this.driverId,
    required this.driverName,
    this.driverImage,
    required this.rating,
    required this.proposedPrice,
    required this.status,
    this.driverPhone,
    this.distanceLabel,
    this.createdAt,
  });

  bool get isPending => status == 'pending';

  @override
  List<Object?> get props => [
        id,
        tripId,
        driverId,
        driverName,
        driverImage,
        rating,
        proposedPrice,
        status,
        driverPhone,
        distanceLabel,
        createdAt,
      ];
}
