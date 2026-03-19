import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/user_entity.dart';
import '../../../../core/constants/supabase_constants.dart';
import '../../../../core/errors/failure.dart';

abstract class AuthRemoteDataSource {
  Future<void> signInWithPhone(String phone);
  Future<UserEntity> verifyOtp({required String phone, required String token});
  Future<UserEntity> signInWithEmail({required String email, required String password});
  Future<void> signUpWithEmail({
    required String email,
    required String password,
    required String username,
    required String displayName,
  });
  Future<void> signInWithGoogle();
  Future<UserEntity> registerUser({
    required String userId,
    required String username,
    required String displayName,
    String? phone,
    String? email,
  });
  Future<void> signOut();
  Future<UserEntity?> getCurrentUser();
  Stream<AuthState> get authStateChanges;
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final SupabaseClient _client;

  AuthRemoteDataSourceImpl(this._client);

  // ─── Phone OTP ────────────────────────────────────────────────────────────

  @override
  Future<void> signInWithPhone(String phone) async {
    try {
      await _client.auth.signInWithOtp(phone: phone);
    } on AuthException catch (e) {
      throw AuthFailure(e.message);
    }
  }

  @override
  Future<UserEntity> verifyOtp({
    required String phone,
    required String token,
  }) async {
    try {
      final response = await _client.auth.verifyOTP(
        phone: phone,
        token: token,
        type: OtpType.sms,
      );
      if (response.user == null) throw const AuthFailure('OTP verification failed');
      return await _fetchProfile(response.user!.id);
    } on AuthException catch (e) {
      throw AuthFailure(e.message);
    } on AuthFailure {
      rethrow;
    } catch (e) {
      throw AuthFailure(e.toString());
    }
  }

  // ─── Email sign-up ────────────────────────────────────────────────────────
  //
  // IMPORTANT: A Postgres trigger (handle_new_user) automatically creates the
  // public.users row whenever a new auth.users record is inserted.
  // Flutter code does NOT manually insert into public.users anymore.

  @override
  Future<void> signUpWithEmail({
    required String email,
    required String password,
    required String username,
    required String displayName,
  }) async {
    try {
      final response = await _client.auth.signUp(
        email: email,
        password: password,
        // Store username + display_name in auth metadata so the DB trigger can
        // pick them up and write them into public.users automatically.
        data: {
          'username': username,
          'display_name': displayName,
        },
      );

      if (response.user == null) {
        throw const AuthFailure('Sign up failed. Please try again.');
      }

      // If session is null, Supabase email confirmation is enabled.
      // The trigger already created the public.users row; tell the user to check
      // email and then sign in.
      if (response.session == null) {
        throw const AuthFailure('SIGNUP_PENDING');
      }

      // Session exists — user is logged in immediately.
      // The trigger already ran and created the profile. Nothing else to do.
    } on AuthException catch (e) {
      throw AuthFailure(e.message);
    } on AuthFailure {
      rethrow;
    }
  }

  // ─── Email sign-in ────────────────────────────────────────────────────────

  @override
  Future<UserEntity> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      if (response.user == null) throw const AuthFailure('Sign in failed.');

      // The trigger guarantees a public.users row exists by now.
      return await _fetchProfile(response.user!.id);
    } on AuthException catch (e) {
      // "Invalid login credentials" from Supabase almost always means one of:
      //   1. Wrong email/password
      //   2. Email not confirmed yet (most common right after signup)
      // Give a clearer message so the user knows what to do.
      final msg = e.message.toLowerCase();
      if (msg.contains('invalid login credentials') ||
          msg.contains('invalid_credentials')) {
        throw const AuthFailure(
          'Incorrect email or password.\n\n'
          'If you just signed up, please confirm your email first '
          '(check your inbox), or disable email confirmation in Supabase.',
        );
      }
      if (msg.contains('email not confirmed')) {
        throw const AuthFailure(
          'Please confirm your email address first.\n'
          'Check your inbox for the confirmation link.',
        );
      }
      throw AuthFailure(e.message);
    } on AuthFailure {
      rethrow;
    } catch (e) {
      throw AuthFailure(e.toString());
    }
  }

  // ─── Google OAuth ─────────────────────────────────────────────────────────

  @override
  Future<void> signInWithGoogle() async {
    try {
      await _client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'com.example.chatterbox://login-callback',
        authScreenLaunchMode: LaunchMode.externalApplication,
      );
    } on AuthException catch (e) {
      throw AuthFailure(e.message);
    }
  }

  // ─── Manual registration (phone OTP new users) ────────────────────────────

  @override
  Future<UserEntity> registerUser({
    required String userId,
    required String username,
    required String displayName,
    String? phone,
    String? email,
  }) async {
    try {
      // Update the auto-created profile row with the provided username /
      // display_name (trigger may have used defaults from metadata).
      await _client.from(SupabaseConstants.usersTable).upsert({
        'id': userId,
        'username': username,
        'display_name': displayName,
        if (phone != null) 'phone': phone,
        if (email != null) 'email': email,
      });
      return await _fetchProfile(userId);
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  // ─── Sign-out ─────────────────────────────────────────────────────────────

  @override
  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } on AuthException catch (e) {
      throw AuthFailure(e.message);
    }
  }

  // ─── Get current user ─────────────────────────────────────────────────────

  @override
  Future<UserEntity?> getCurrentUser() async {
    final authUser = _client.auth.currentUser;
    if (authUser == null) return null;
    try {
      return await _fetchProfile(authUser.id);
    } catch (_) {
      return null;
    }
  }

  @override
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  // ─── Helpers ──────────────────────────────────────────────────────────────

  /// Reads the user's profile from public.users.
  /// Retries once after a short delay to account for trigger propagation lag.
  Future<UserEntity> _fetchProfile(String userId) async {
    var data = await _client
        .from(SupabaseConstants.usersTable)
        .select()
        .eq('id', userId)
        .maybeSingle();

    if (data == null) {
      // Trigger may still be propagating — wait briefly and retry once.
      await Future.delayed(const Duration(milliseconds: 800));
      data = await _client
          .from(SupabaseConstants.usersTable)
          .select()
          .eq('id', userId)
          .maybeSingle();
    }

    if (data == null) {
      throw const AuthFailure(
          'Profile not found. The database trigger may not be set up.');
    }

    return _mapToUserEntity(data as Map<String, dynamic>);
  }

  UserEntity _mapToUserEntity(Map<String, dynamic> data) {
    return UserEntity(
      id: data['id'] as String,
      phone: data['phone'] as String?,
      email: data['email'] as String?,
      username: data['username'] as String,
      displayName: data['display_name'] as String,
      avatarUrl: data['avatar_url'] as String?,
      statusMsg: data['status_msg'] as String? ?? 'Hey there! I am using Heartbeat.',
      lastSeen: data['last_seen'] != null
          ? DateTime.parse(data['last_seen'] as String)
          : null,
      isOnline: data['is_online'] as bool? ?? false,
      createdAt: DateTime.parse(data['created_at'] as String),
    );
  }
}