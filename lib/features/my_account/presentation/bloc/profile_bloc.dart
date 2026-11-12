import 'dart:io';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:motorent/features/my_account/domain/entities/profile_data.dart';
import 'package:motorent/features/my_account/domain/usecases/get_profile.dart';
import 'package:motorent/features/my_account/domain/usecases/update_profile.dart';

part 'profile_event.dart';
part 'profile_state.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final GetProfile getProfile;
  final UpdateProfile updateProfile;

  ProfileData? _current;

  ProfileBloc({
    required this.getProfile,
    required this.updateProfile,
  }) : super(const ProfileInitial()) {
    on<FetchProfileEvent>(_onFetch);
    on<UpdateProfileEvent>(_onUpdate);
  }

  Future<void> _onFetch(
    FetchProfileEvent event,
    Emitter<ProfileState> emit,
  ) async {
    emit(const ProfileLoading());

    final result = await getProfile();
    result.fold(
      (failure) => emit(ProfileError(failure.message, data: _current)),
      (data) {
        _current = data;
        emit(ProfileLoadedSuccess(data));
      },
    );
  }

  Future<void> _onUpdate(
    UpdateProfileEvent event,
    Emitter<ProfileState> emit,
  ) async {
    final current = _current;
    if (current == null) {
      emit(const ProfileError('لا توجد بيانات للملف الشخصي'));
      return;
    }

    emit(ProfileUpdateLoading(current));

    final result = await updateProfile(
      name: event.name,
      phone: event.phone,
      email: event.email,
      vehicleType: event.vehicleType,
      password: event.password,
      passwordConfirmation: event.passwordConfirmation,
      governorate: event.governorate,
      area: event.area,
      imageFile: event.imageFile,
      nidImageFile: event.nidImageFile,
    );

    result.fold(
      (failure) {
        emit(ProfileError(failure.message, data: current));
        emit(ProfileLoadedSuccess(current));
      },
      (user) {
        final updated = current.copyWith(user: user);
        _current = updated;
        emit(ProfileUpdateSuccess(updated));
        emit(ProfileLoadedSuccess(updated));
      },
    );
  }
}
