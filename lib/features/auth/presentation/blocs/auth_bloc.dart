import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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

class AuthSignUpPendingState extends AuthState {}

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

  // Rate limiting: track last auth attempt time
  DateTime? _lastAuthAttempt;
  static const _rateLimitDuration = Duration(seconds: 2);

  // Auth state subscription (keeps bloc alive to Supabase session changes)
  StreamSubscription<AuthState>? _authSubscription;

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

    // ── Listen to Supabase auth state changes ─────────────────────────────
    // This ensures session restore after app restart is handled automatically.
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final event = data.event;
      final session = data.session;

      if (event == AuthChangeEvent.signedIn && session != null) {
        // Session was restored from storage OR user just signed in.
        // Only fire if we're not already in an authenticated state to avoid
        // duplicate loads.
        if (state is! AuthAuthenticatedState && state is! AuthLoadingState) {
          add(AuthCheckStatusEvent());
        }
      } else if (event == AuthChangeEvent.signedOut) {
        if (state is! AuthUnauthenticatedState) {
          emit(AuthUnauthenticatedState());
        }
      } else if (event == AuthChangeEvent.tokenRefreshed && session != null) {
        // Session token refreshed silently — no UI change needed.
      }
    });
  }

  bool _isRateLimited() {
    if (_lastAuthAttempt == null) return false;
    return DateTime.now().difference(_lastAuthAttempt!) < _rateLimitDuration;
  }

  void _recordAuthAttempt() => _lastAuthAttempt = DateTime.now();

  // ── Check persisted session (called on app start from SplashScreen) ──────

  Future<void> _onCheckStatus(
      AuthCheckStatusEvent event, Emitter<AuthState> emit) async {
    emit(AuthLoadingState());
    try {
      // First check if there is a live Supabase session (persisted on disk).
      final session = Supabase.instance.client.auth.currentSession;
      if (session == null) {
        emit(AuthUnauthenticatedState());
        return;
      }

      // Session exists — try to load the public profile.
      final user = await getCurrentUser();
      if (user != null) {
        emit(AuthAuthenticatedState(user));
      } else {
        // We have a valid auth session but no profile row yet (e.g., trigger
        // ran but RLS migration not done yet). Build a minimal entity from
        // the auth user so the user is not forced to re-login.
        final authUser = Supabase.instance.client.auth.currentUser!;
        final meta = authUser.userMetadata ?? {};
        final email = authUser.email ?? '';
        final username = (meta['username'] as String?) ??
            email.split('@').first.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_');

        emit(AuthAuthenticatedState(UserEntity(
          id: authUser.id,
          email: email,
          username: username,
          displayName: (meta['display_name'] as String?) ?? username,
          statusMsg: 'Hey there! I am using Heartbeat.',
          isOnline: true,
          createdAt: DateTime.now(),
        )));
      }
    } catch (_) {
      // Even on network failure, if there's a session keep the user logged in.
      final session = Supabase.instance.client.auth.currentSession;
      if (session != null) {
        final authUser = Supabase.instance.client.auth.currentUser!;
        final meta = authUser.userMetadata ?? {};
        final email = authUser.email ?? '';
        final username = (meta['username'] as String?) ??
            email.split('@').first.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_');
        emit(AuthAuthenticatedState(UserEntity(
          id: authUser.id,
          email: email,
          username: username,
          displayName: (meta['display_name'] as String?) ?? username,
          statusMsg: 'Hey there! I am using Heartbeat.',
          isOnline: true,
          createdAt: DateTime.now(),
        )));
      } else {
        emit(AuthUnauthenticatedState());
      }
    }
  }

  // ── Phone ─────────────────────────────────────────────────────────────────

  Future<void> _onSignInWithPhone(
      AuthSignInWithPhoneEvent event, Emitter<AuthState> emit) async {
    if (_isRateLimited()) {
      emit(AuthErrorState('Please wait a moment before trying again.'));
      return;
    }
    _recordAuthAttempt();
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
      final user =
          await verifyOtp(phone: event.phone, token: event.token);
      emit(AuthAuthenticatedState(user));
    } on AuthFailure catch (e) {
      if (e.message == 'NEW_USER') {
        final authUser = Supabase.instance.client.auth.currentUser;
        emit(AuthNewUserState(
          userId: authUser?.id ?? '',
          phone: event.phone,
        ));
      } else {
        emit(AuthErrorState(e.message));
      }
    } catch (e) {
      emit(AuthErrorState('OTP verification failed. Try again.'));
    }
  }

  // ── Email Sign-In ─────────────────────────────────────────────────────────

  Future<void> _onSignInWithEmail(
      AuthSignInWithEmailEvent event, Emitter<AuthState> emit) async {
    if (_isRateLimited()) {
      emit(AuthErrorState('Please wait a moment before trying again.'));
      return;
    }
    _recordAuthAttempt();
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

  // ── Email Sign-Up ─────────────────────────────────────────────────────────

  Future<void> _onSignUpWithEmail(
      AuthSignUpWithEmailEvent event, Emitter<AuthState> emit) async {
    if (_isRateLimited()) {
      emit(AuthErrorState('Please wait a moment before trying again.'));
      return;
    }
    _recordAuthAttempt();
    emit(AuthLoadingState());
    try {
      await signUpWithEmail(
        email: event.email,
        password: event.password,
        username: event.username,
        displayName: event.displayName,
      );
      // If we reach here, no exception was thrown → session established.
      final user = await getCurrentUser();
      if (user != null) {
        emit(AuthAuthenticatedState(user));
      } else {
        emit(AuthSignUpPendingState());
      }
    } on AuthFailure catch (e) {
      if (e.message == 'SIGNUP_PENDING') {
        emit(AuthSignUpPendingState());
      } else {
        emit(AuthErrorState(e.message));
      }
    } catch (e) {
      emit(AuthErrorState('Sign up failed. Try again.'));
    }
  }

  // ── Google ────────────────────────────────────────────────────────────────

  Future<void> _onSignInWithGoogle(
      AuthSignInWithGoogleEvent event, Emitter<AuthState> emit) async {
    emit(AuthLoadingState());
    try {
      await signInWithGoogle();
      // OAuth result arrives via deep link → authStateChanges listener handles it
      emit(AuthUnauthenticatedState());
    } on AuthFailure catch (e) {
      emit(AuthErrorState(e.message));
    } catch (_) {
      emit(AuthErrorState('Google sign-in failed. Try again.'));
    }
  }

  // ── Sign-Out ──────────────────────────────────────────────────────────────

  Future<void> _onSignOut(
      AuthSignOutEvent event, Emitter<AuthState> emit) async {
    emit(AuthLoadingState());
    try {
      await signOut();
      emit(AuthUnauthenticatedState());
    } catch (_) {
      emit(AuthUnauthenticatedState());
    }
  }

  @override
  Future<void> close() {
    _authSubscription?.cancel();
    return super.close();
  }
}
