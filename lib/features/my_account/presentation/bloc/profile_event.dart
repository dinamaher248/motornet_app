part of 'profile_bloc.dart';

abstract class ProfileEvent extends Equatable {
  const ProfileEvent();

  @override
  List<Object?> get props => [];
}

class FetchProfileEvent extends ProfileEvent {
  const FetchProfileEvent();
}

class UpdateProfileEvent extends ProfileEvent {
  final String? name;
  final String? phone;
  final String? email;
  final String? vehicleType;
  final String? password;
  final String? passwordConfirmation;
  final String? governorate;
  final String? area;
  final File? imageFile;
  final File? nidImageFile;

  const UpdateProfileEvent({
    this.name,
    this.phone,
    this.email,
    this.vehicleType,
    this.password,
    this.passwordConfirmation,
    this.governorate,
    this.area,
    this.imageFile,
    this.nidImageFile,
  });

  @override
  List<Object?> get props => [
        name,
        phone,
        email,
        vehicleType,
        password,
        passwordConfirmation,
        governorate,
        area,
        imageFile?.path,
        nidImageFile?.path,
      ];
}
