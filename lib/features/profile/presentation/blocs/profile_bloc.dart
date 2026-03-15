import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../domain/usecases/get_profile.dart';
import '../../domain/usecases/update_profile.dart';

// Events
abstract class ProfileEvent extends Equatable {
  @override List<Object?> get props => [];
}
class ProfileLoadEvent extends ProfileEvent {
  final String userId;
  ProfileLoadEvent(this.userId);
  @override List<Object?> get props => [userId];
}
class ProfileUpdateEvent extends ProfileEvent {
  final String userId;
  final String? displayName, statusMsg, avatarPath;
  ProfileUpdateEvent({
    required this.userId,
    this.displayName,
    this.statusMsg,
    this.avatarPath,
  });
  @override List<Object?> get props => [userId, displayName, statusMsg];
}

// States
abstract class ProfileState extends Equatable {
  @override List<Object?> get props => [];
}
class ProfileInitialState extends ProfileState {}
class ProfileLoadingState extends ProfileState {}
class ProfileLoadedState extends ProfileState {
  final UserEntity user;
  ProfileLoadedState(this.user);
  @override List<Object?> get props => [user];
}
class ProfileUpdatingState extends ProfileState {
  final UserEntity user;
  ProfileUpdatingState(this.user);
  @override List<Object?> get props => [user];
}
class ProfileErrorState extends ProfileState {
  final String message;
  ProfileErrorState(this.message);
  @override List<Object?> get props => [message];
}

// BLoC
class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final GetProfile getProfile;
  final UpdateProfile updateProfile;

  ProfileBloc({required this.getProfile, required this.updateProfile})
      : super(ProfileInitialState()) {
    on<ProfileLoadEvent>(_onLoad);
    on<ProfileUpdateEvent>(_onUpdate);
  }

  Future<void> _onLoad(ProfileLoadEvent event, Emitter<ProfileState> emit) async {
    emit(ProfileLoadingState());
    try {
      final user = await getProfile(event.userId);
      emit(ProfileLoadedState(user));
    } catch (e) {
      emit(ProfileErrorState(e.toString()));
    }
  }

  Future<void> _onUpdate(ProfileUpdateEvent event, Emitter<ProfileState> emit) async {
    final current = state;
    if (current is ProfileLoadedState) emit(ProfileUpdatingState(current.user));

    try {
      final updated = await updateProfile(
        userId: event.userId,
        displayName: event.displayName,
        statusMsg: event.statusMsg,
        avatarPath: event.avatarPath,
      );
      emit(ProfileLoadedState(updated));
    } catch (e) {
      emit(ProfileErrorState(e.toString()));
    }
  }
}
