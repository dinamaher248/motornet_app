part of 'profile_bloc.dart';

abstract class ProfileState extends Equatable {
  const ProfileState();

  @override
  List<Object?> get props => [];
}

class ProfileInitial extends ProfileState {
  const ProfileInitial();
}

class ProfileLoading extends ProfileState {
  const ProfileLoading();
}

class ProfileLoadedSuccess extends ProfileState {
  final ProfileData data;

  const ProfileLoadedSuccess(this.data);

  @override
  List<Object?> get props => [data];
}

class ProfileUpdateLoading extends ProfileState {
  final ProfileData data;

  const ProfileUpdateLoading(this.data);

  @override
  List<Object?> get props => [data];
}

class ProfileUpdateSuccess extends ProfileState {
  final ProfileData data;
  final String message;

  const ProfileUpdateSuccess(
    this.data, {
    this.message = 'تم تحديث البيانات بنجاح',
  });

  @override
  List<Object?> get props => [data, message];
}

class ProfileError extends ProfileState {
  final String message;
  final ProfileData? data;

  const ProfileError(this.message, {this.data});

  @override
  List<Object?> get props => [message, data];
}
