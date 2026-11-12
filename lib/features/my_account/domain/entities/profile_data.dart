import 'package:equatable/equatable.dart';

class ProfileUser extends Equatable {
  final int id;
  final String name;
  final String phone;
  final String? image;
  final String? email;
  final String? title;
  final String? vehicleType;
  final String? vehicleTypeLabel;
  final String? nidImage;
  final String? governorate;
  final String? area;

  const ProfileUser({
    required this.id,
    required this.name,
    required this.phone,
    this.image,
    this.email,
    this.title,
    this.vehicleType,
    this.vehicleTypeLabel,
    this.nidImage,
    this.governorate,
    this.area,
  });

  bool get isDriver =>
      (title ?? '').toLowerCase() == 'driver' ||
      (title ?? '').toLowerCase() == 'سائق';

  ProfileUser copyWith({
    int? id,
    String? name,
    String? phone,
    String? image,
    String? email,
    String? title,
    String? vehicleType,
    String? vehicleTypeLabel,
    String? nidImage,
    String? governorate,
    String? area,
  }) {
    return ProfileUser(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      image: image ?? this.image,
      email: email ?? this.email,
      title: title ?? this.title,
      vehicleType: vehicleType ?? this.vehicleType,
      vehicleTypeLabel: vehicleTypeLabel ?? this.vehicleTypeLabel,
      nidImage: nidImage ?? this.nidImage,
      governorate: governorate ?? this.governorate,
      area: area ?? this.area,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        phone,
        image,
        email,
        title,
        vehicleType,
        vehicleTypeLabel,
        nidImage,
        governorate,
        area,
      ];
}

class ProfileSettings extends Equatable {
  final String supportPhone;
  final String privacyPolicyUrl;

  const ProfileSettings({
    required this.supportPhone,
    required this.privacyPolicyUrl,
  });

  @override
  List<Object?> get props => [supportPhone, privacyPolicyUrl];
}

class ProfileData extends Equatable {
  final ProfileUser user;
  final ProfileSettings settings;
  final int bookingsCount;

  const ProfileData({
    required this.user,
    required this.settings,
    this.bookingsCount = 0,
  });

  ProfileData copyWith({
    ProfileUser? user,
    ProfileSettings? settings,
    int? bookingsCount,
  }) {
    return ProfileData(
      user: user ?? this.user,
      settings: settings ?? this.settings,
      bookingsCount: bookingsCount ?? this.bookingsCount,
    );
  }

  @override
  List<Object?> get props => [user, settings, bookingsCount];
}
