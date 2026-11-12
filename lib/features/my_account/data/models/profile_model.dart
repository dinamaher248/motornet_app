import 'package:motorent/constants/app_support.dart';
import 'package:motorent/features/my_account/domain/entities/profile_data.dart';

class ProfileModel {
  static ProfileData fromJson(Map<String, dynamic> json) {
    final data = json['data'] is Map
        ? Map<String, dynamic>.from(json['data'] as Map)
        : json;

    final userRaw = data['user'] is Map
        ? Map<String, dynamic>.from(data['user'] as Map)
        : data;

    final settingsRaw = data['settings'] is Map
        ? Map<String, dynamic>.from(data['settings'] as Map)
        : <String, dynamic>{};

    final bookings = int.tryParse(
          '${userRaw['bookings_count'] ?? data['bookings_count'] ?? json['bookings_count'] ?? 0}',
        ) ??
        0;

    return ProfileData(
      user: ProfileUserModel.fromJson(userRaw),
      settings: ProfileSettingsModel.fromJson(settingsRaw),
      bookingsCount: bookings,
    );
  }
}

class ProfileUserModel extends ProfileUser {
  const ProfileUserModel({
    required super.id,
    required super.name,
    required super.phone,
    super.image,
    super.email,
    super.title,
    super.vehicleType,
    super.vehicleTypeLabel,
    super.nidImage,
    super.governorate,
    super.area,
  });

  factory ProfileUserModel.fromJson(Map<String, dynamic> json) {
    return ProfileUserModel(
      id: _asInt(json['id']),
      name: (json['name'] ?? '').toString(),
      phone: (json['phone'] ?? json['mobile'] ?? '').toString(),
      image: json['image']?.toString(),
      email: json['email']?.toString(),
      title: json['title']?.toString(),
      vehicleType:
          (json['vehicle_type'] ?? json['vehicleType'])?.toString(),
      vehicleTypeLabel:
          (json['vehicle_type_label'] ?? json['vehicleTypeLabel'])
              ?.toString(),
      nidImage: (json['nid_image'] ?? json['nidImage'])?.toString(),
      governorate: json['governorate']?.toString(),
      area: json['area']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'phone': phone,
        'image': image,
        'email': email,
        'title': title,
        'vehicle_type': vehicleType,
        'vehicle_type_label': vehicleTypeLabel,
        'nid_image': nidImage,
        'governorate': governorate,
        'area': area,
      };

  static int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}

class ProfileSettingsModel extends ProfileSettings {
  const ProfileSettingsModel({
    required super.supportPhone,
    required super.privacyPolicyUrl,
  });

  factory ProfileSettingsModel.fromJson(Map<String, dynamic> json) {
    final phone = (json['support_phone'] ??
            json['supportPhone'] ??
            AppSupport.phone)
        .toString();
    final url = (json['privacy_policy_url'] ??
            json['privacyPolicyUrl'] ??
            '')
        .toString();

    return ProfileSettingsModel(
      supportPhone: phone.isEmpty ? AppSupport.phone : phone,
      privacyPolicyUrl: url,
    );
  }
}
