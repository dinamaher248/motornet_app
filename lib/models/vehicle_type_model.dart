class VehicleTypeModel {
  final int id;
  final String key;
  final String nameAr;
  final String? nameEn;
  final double? serviceRadiusKm;
  final String? category;

  VehicleTypeModel({
    required this.id,
    required this.key,
    required this.nameAr,
    this.nameEn,
    this.serviceRadiusKm,
    this.category,
  });

  factory VehicleTypeModel.fromJson(Map<String, dynamic> json) {
    final radiusRaw = json['coverage_range_km'] ??
        json['service_radius_km'] ??
        json['coverage_range'] ??
        json['radius_km'];

    return VehicleTypeModel(
      id: json['id'] is int
          ? json['id'] as int
          : int.tryParse('${json['id']}') ?? 0,
      // Always use the admin/DB key for API requests (not canonical_key).
      // canonical_key slugifies "Tuk Tuk" → "tuk_tuk" which the server rejects.
      key: (json['key'] ?? json['canonical_key'] ?? '') as String,
      nameAr: (json['name_ar'] ?? json['name'] ?? '') as String,
      nameEn: json['name_en'] as String?,
      serviceRadiusKm: radiusRaw == null
          ? null
          : double.tryParse(radiusRaw.toString()),
      category: json['category']?.toString(),
    );
  }

  String get displayName => nameAr.isNotEmpty ? nameAr : (nameEn ?? key);

  bool get isQuickTrip =>
      category == null || category == 'quick_trip' || category == 'quick';

  bool get isGoods => category == 'goods';
}
