class Driver {
  final int id;
  final String? name;
  final String? username;
  final String? type;
  final String? title;
  final int coins;
  final String? email;
  final String? emailVerifiedAt;
  final String? phone;
  final String? nidImage;
  final String? image;
  final String? vehicleType;
  final String? area;
  final int isPaid;
  final int isApproved;
  final String? subscriptionEndDate;
  final int? isAdmin;
  final String? createdAt;
  final String? updatedAt;
  bool? is_booked = false;
  int? is_online ;
  final String? governorate;

  Driver({
    required this.id,
    required this.name,
    required this.username,
    required this.type,
    required this.title,
    required this.coins,
    required this.email,
    this.emailVerifiedAt,
    this.phone,
    this.nidImage,
    this.image,
    this.vehicleType,
    this.area,
    required this.isPaid,
    required this.isApproved,
    this.subscriptionEndDate,
    required this.isAdmin,
    this.createdAt,
    this.updatedAt,
    this.is_booked,
    this.is_online,
    this.governorate,
  });

  static bool? _toBool(dynamic value) {
    if (value == null) return null;
    if (value is bool) return value;
    if (value is num) return value != 0;
    return value.toString() == '1' || value.toString().toLowerCase() == 'true';
  }

  static int _toInt(dynamic value, {int fallback = 0}) {
    if (value == null) return fallback;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString()) ?? fallback;
  }

  factory Driver.fromJson(Map<String, dynamic> json) {
    return Driver(
      id: _toInt(json['id']),
      name: json['name']?.toString(),
      username: json['username']?.toString(),
      type: json['type']?.toString(),
      title: json['title']?.toString(),
      coins: _toInt(json['coins']),
      email: json['email']?.toString(),
      emailVerifiedAt: json['email_verified_at']?.toString(),
      phone: json['phone']?.toString(),
      nidImage: json['nid_image']?.toString(),
      image: json['image']?.toString(),
      vehicleType: json['vehicle_type']?.toString(),
      area: json['area']?.toString(),
      isPaid: _toInt(json['is_paid']),
      isApproved: _toInt(json['is_approved']),
      subscriptionEndDate: json['subscription_end_date']?.toString(),
      isAdmin: _toInt(json['is_admin']),
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
      is_booked: _toBool(json['is_booked']),
      is_online: json['is_online'] == null ? null : _toInt(json['is_online']),
      governorate: json['governorate']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'username': username,
      'type': type,
      'title': title,
      'coins': coins,
      'email': email,
      'email_verified_at': emailVerifiedAt,
      'phone': phone,
      'nid_image': nidImage,
      'image': image,
      'vehicle_type': vehicleType,
      'area': area,
      'is_paid': isPaid,
      'is_approved': isApproved,
      'subscription_end_date': subscriptionEndDate,
      'is_admin': isAdmin,
      'created_at': createdAt,
      'is_booked': is_booked,
      'is_online': is_online,
      'governorate': governorate,
    };
  }
}
