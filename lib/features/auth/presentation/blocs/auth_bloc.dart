import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/usecases/sign_in_with_phone.dart';
import '../../domain/usecases/sign_in_with_google.dart';
import '../../domain/usecases/sign_in_with_email.dart';
import '../../domain/usecases/sign_up_with_email.dart';
import '../../domain/usecases/verify_otp.dart';
import '../../domain/usecases/sign_out.dart';
import '../../domain/usecases/get_current_user.dart';
import '../../../../core/errors/failure.dart';

// ─── Events ───────────────────────────────────────────────────────────────────

abstract class AuthEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class AuthCheckStatusEvent extends AuthEvent {}

class AuthSignInWithPhoneEvent extends AuthEvent {
  final String phone;
  AuthSignInWithPhoneEvent(this.phone);
  @override
  List<Object?> get props => [phone];
}

class AuthVerifyOtpEvent extends AuthEvent {
  final String phone, token;
  AuthVerifyOtpEvent({required this.phone, required this.token});
  @override
  List<Object?> get props => [phone, token];
}

class AuthSignInWithEmailEvent extends AuthEvent {
  final String email, password;
  AuthSignInWithEmailEvent({required this.email, required this.password});
  @override
  List<Object?> get props => [email, password];
}

class AuthSignUpWithEmailEvent extends AuthEvent {
  final String email, password, username, displayName;
  AuthSignUpWithEmailEvent({
    required this.email,
    required this.password,
    required this.username,
    required this.displayName,
  });
  @override
  List<Object?> get props => [email, username];
}

class AuthSignInWithGoogleEvent extends AuthEvent {}

class AuthRegisterEvent extends AuthEvent {
  final String userId, username, displayName;
  final String? phone, email;
  AuthRegisterEvent({
    required this.userId,
    required this.username,
    required this.displayName,
    this.phone,
    this.email,
  });
  @override
  List<Object?> get props => [userId, username, displayName];
}

class AuthSignOutEvent extends AuthEvent {}

// ─── States ───────────────────────────────────────────────────────────────────

abstract class AuthState extends Equatable {
  @override
  List<Object?> get props => [];
}

class AuthInitialState extends AuthState {}

class AuthLoadingState extends AuthState {}

class AuthOtpSentState extends AuthState {
  final String phone;
  AuthOtpSentState(this.phone);
  @override
  List<Object?> get props => [phone];
}

class AuthAuthenticatedState extends AuthState {
  final UserEntity user;
  AuthAuthenticatedState(this.user);
  @override
  List<Object?> get props => [user];
}

class AuthNewUserState extends AuthState {
  final String userId;
  final String? phone, email;
  AuthNewUserState({required this.userId, this.phone, this.email});
  @override
  List<Object?> get props => [userId];
}

class AuthUnauthenticatedState extends AuthState {}

class AuthErrorState extends AuthState {
  final String message;
  AuthErrorState(this.message);
  @override
  List<Object?> get props => [message];
}

// ─── BLoC ─────────────────────────────────────────────────────────────────────

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final SignInWithPhone signInWithPhone;
  final SignInWithGoogle signInWithGoogle;
  final SignInWithEmail signInWithEmail;
  final SignUpWithEmail signUpWithEmail;
  final VerifyOtp verifyOtp;
  final SignOut signOut;
  final GetCurrentUser getCurrentUser;

  AuthBloc({
    required this.signInWithPhone,
    required this.signInWithGoogle,
    required this.signInWithEmail,
    required this.signUpWithEmail,
    required this.verifyOtp,
    required this.signOut,
    required this.getCurrentUser,
  }) : super(AuthInitialState()) {
    on<AuthCheckStatusEvent>(_onCheckStatus);
    on<AuthSignInWithPhoneEvent>(_onSignInWithPhone);
    on<AuthVerifyOtpEvent>(_onVerifyOtp);
    on<AuthSignInWithEmailEvent>(_onSignInWithEmail);
    on<AuthSignUpWithEmailEvent>(_onSignUpWithEmail);
    on<AuthSignInWithGoogleEvent>(_onSignInWithGoogle);
    on<AuthSignOutEvent>(_onSignOut);
  }

  Future<void> _onCheckStatus(
      AuthCheckStatusEvent event, Emitter<AuthState> emit) async {
    emit(AuthLoadingState());
    try {
      final user = await getCurrentUser();
      if (user != null) {
        emit(AuthAuthenticatedState(user));
      } else {
        emit(AuthUnauthenticatedState());
      }
    } catch (_) {
      emit(AuthUnauthenticatedState());
    }
  }

  Future<void> _onSignInWithPhone(
      AuthSignInWithPhoneEvent event, Emitter<AuthState> emit) async {
    emit(AuthLoadingState());
    try {
      await signInWithPhone(event.phone);
      emit(AuthOtpSentState(event.phone));
    } on AuthFailure catch (e) {
      emit(AuthErrorState(e.message));
    } catch (e) {
      emit(AuthErrorState('Something went wrong. Try again.'));
    }
  }

  Future<void> _onVerifyOtp(
      AuthVerifyOtpEvent event, Emitter<AuthState> emit) async {
    emit(AuthLoadingState());
    try {
      final user = await verifyOtp(phone: event.phone, token: event.token);
      emit(AuthAuthenticatedState(user));
    } on AuthFailure catch (e) {
      if (e.message == 'NEW_USER') {
        emit(AuthNewUserState(phone: event.phone, userId: ''));
      } else {
        emit(AuthErrorState(e.message));
      }
    } catch (e) {
      emit(AuthErrorState('OTP verification failed. Try again.'));
    }
  }

  Future<void> _onSignInWithEmail(
      AuthSignInWithEmailEvent event, Emitter<AuthState> emit) async {
    emit(AuthLoadingState());
    try {
      final user = await signInWithEmail(
        email: event.email,
        password: event.password,
      );
      emit(AuthAuthenticatedState(user));
    } on AuthFailure catch (e) {
      emit(AuthErrorState(e.message));
    } catch (e) {
      emit(AuthErrorState('Sign in failed. Check your credentials and try again.'));
    }
  }

  Future<void> _onSignUpWithEmail(
      AuthSignUpWithEmailEvent event, Emitter<AuthState> emit) async {
    emit(AuthLoadingState());
    try {
      final user = await signUpWithEmail(
        email: event.email,
        password: event.password,
        username: event.username,
        displayName: event.displayName,
      );
      emit(AuthAuthenticatedState(user));
    } on AuthFailure catch (e) {
      emit(AuthErrorState(e.message));
    } catch (e) {
      emit(AuthErrorState('Sign up failed. Try again.'));
    }
  }

  Future<void> _onSignInWithGoogle(
      AuthSignInWithGoogleEvent event, Emitter<AuthState> emit) async {
    emit(AuthLoadingState());
    try {
      await signInWithGoogle();
      // Session will be picked up via authStateChanges deep-link callback
      // For now emit unauthenticated so UI can respond if needed
      emit(AuthUnauthenticatedState());
    } on AuthFailure catch (e) {
      emit(AuthErrorState(e.message));
    } catch (e) {
      emit(AuthErrorState('Google sign in failed. Try again.'));
    }
  }

  Future<void> _onSignOut(
      AuthSignOutEvent event, Emitter<AuthState> emit) async {
    try {
      await signOut();
    } catch (_) {}
    emit(AuthUnauthenticatedState());
  }
}
