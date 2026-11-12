class TripDriverSummary {
  final int? id;
  final String? name;
  final String? image;
  final double rating;
  final String? vehicleTypeLabel;
  final String? phone;
  final bool canCall;
  final bool canChat;

  TripDriverSummary({
    this.id,
    this.name,
    this.image,
    this.rating = 0,
    this.vehicleTypeLabel,
    this.phone,
    this.canCall = false,
    this.canChat = false,
  });

  factory TripDriverSummary.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return TripDriverSummary();
    }

    return TripDriverSummary(
      id: json['id'] as int?,
      name: json['name']?.toString(),
      image: json['image']?.toString(),
      rating: double.tryParse(
            (json['avg_rating'] ?? json['rating'])?.toString() ?? '',
          ) ??
          0,
      vehicleTypeLabel: json['vehicle_type_label']?.toString(),
      phone: json['phone']?.toString(),
      canCall: json['can_call'] == true,
      canChat: json['can_chat'] == true,
    );
  }
}

class TripOfferItem {
  final int id;
  final double amount;
  final String status;
  final TripDriverSummary driver;
  final String? createdAt;

  TripOfferItem({
    required this.id,
    required this.amount,
    required this.status,
    required this.driver,
    this.createdAt,
  });

  factory TripOfferItem.fromJson(Map<String, dynamic> json) {
    return TripOfferItem(
      id: json['id'] as int? ?? 0,
      amount: double.tryParse(json['amount']?.toString() ?? '') ?? 0,
      status: json['status']?.toString() ?? 'pending',
      driver: TripDriverSummary.fromJson(
        json['driver'] as Map<String, dynamic>?,
      ),
      createdAt: json['created_at']?.toString(),
    );
  }
}

class TripRequestItem {
  final int id;
  final String serviceType;
  final String vehicleType;
  final String vehicleTypeLabel;
  final String pickLoc;
  final String targetLoc;
  final double? distanceKm;
  final String description;
  final String? contactPhone;
  final String? notes;
  final String status;
  final int offersCount;
  final String? createdAt;
  final TripDriverSummary? acceptedDriver;
  final int? rideBookId;

  TripRequestItem({
    required this.id,
    required this.serviceType,
    required this.vehicleType,
    required this.vehicleTypeLabel,
    required this.pickLoc,
    required this.targetLoc,
    this.distanceKm,
    required this.description,
    this.contactPhone,
    this.notes,
    required this.status,
    this.offersCount = 0,
    this.createdAt,
    this.acceptedDriver,
    this.rideBookId,
  });

  factory TripRequestItem.fromJson(Map<String, dynamic> json) {
    return TripRequestItem(
      id: json['id'] as int? ?? 0,
      serviceType: json['service_type']?.toString() ?? '',
      vehicleType: json['vehicle_type']?.toString() ?? '',
      vehicleTypeLabel: json['vehicle_type_label']?.toString() ?? '',
      pickLoc: json['pick_loc']?.toString() ?? '',
      targetLoc: json['target_loc']?.toString() ?? '',
      distanceKm: double.tryParse(json['distance_km']?.toString() ?? ''),
      description: json['description']?.toString() ?? '',
      contactPhone: json['contact_phone']?.toString(),
      notes: json['notes']?.toString(),
      status: json['status']?.toString() ?? '',
      offersCount: json['offers_count'] as int? ?? 0,
      createdAt: json['created_at']?.toString(),
      acceptedDriver: json['accepted_driver'] != null
          ? TripDriverSummary.fromJson(
              json['accepted_driver'] as Map<String, dynamic>,
            )
          : null,
      rideBookId: json['ride_book_id'] as int?,
    );
  }

  bool get canCancel => status == 'awaiting_offers';

  String get statusLabel {
    switch (status) {
      case 'awaiting_offers':
        return 'بانتظار العروض';
      case 'in_progress':
        return 'جاري التنفيذ';
      case 'handed_to_driver':
        return 'تم التسليم للسائق';
      case 'completed':
        return 'مكتمل';
      case 'cancelled':
        return 'ملغي';
      default:
        return status;
    }
  }

  String get serviceTypeLabel =>
      serviceType == 'quick_trip' ? 'مشوار سريع' : 'نقل بضائع';
}
