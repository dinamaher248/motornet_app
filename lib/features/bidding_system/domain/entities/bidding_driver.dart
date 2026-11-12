import 'package:equatable/equatable.dart';

/// Nested driver info returned with trip details after an offer is accepted.
class BiddingDriver extends Equatable {
  final int id;
  final String name;
  final String? image;
  final String? phone;
  final double rating;

  const BiddingDriver({
    required this.id,
    required this.name,
    this.image,
    this.phone,
    this.rating = 0,
  });

  @override
  List<Object?> get props => [id, name, image, phone, rating];
}
