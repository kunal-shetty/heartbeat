import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/user_entity.dart';
import '../../../../core/constants/supabase_constants.dart';
import '../../../../core/errors/failure.dart';

abstract class AuthRemoteDataSource {
  Future<void> signInWithPhone(String phone);
  Future<UserEntity> verifyOtp({required String phone, required String token});
  Future<UserEntity> signInWithEmail({required String email, required String password});
  Future<UserEntity> signUpWithEmail({
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
      return await _getOrCreateUser(response.user!);
    } on AuthException catch (e) {
      throw AuthFailure(e.message);
    }
  }


@override
Future<UserEntity> signUpWithEmail({
  required String email,
  required String password,
  required String username,
  required String displayName,
}) async {
  try {
    final response = await _client.auth.signUp(
      email: email,
      password: password,
    );
    if (response.user == null) throw const AuthFailure('Sign up failed');

    await _client.from(SupabaseConstants.usersTable).insert({
      'id': response.user!.id,
      'email': email,
      'username': username,
      'display_name': displayName,
    });

    return _mapToUserEntity({
      'id': response.user!.id,
      'email': email,
      'username': username,
      'display_name': displayName,
      'status_msg': 'Hey there! I am using Chatter.',
      'is_online': false,
      'created_at': DateTime.now().toIso8601String(),
    });
  } on AuthException catch (e) {
    throw AuthFailure(e.message);
  }
}
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
      if (response.user == null) throw const AuthFailure('Sign in failed');
      return await _getOrCreateUser(response.user!);
    } on AuthException catch (e) {
      throw AuthFailure(e.message);
    }
  }

  @override
  // signInWithOAuth just launches the browser — it returns immediately.
  // The actual session is delivered via the deep link redirect and picked
  // up automatically by supabase_flutter via onAuthStateChange.
  // The AuthBloc listens to authStateChanges so it will handle the rest.
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

  @override
  Future<UserEntity> registerUser({
    required String userId,
    required String username,
    required String displayName,
    String? phone,
    String? email,
  }) async {
    try {
      final data = {
        'id': userId,
        'username': username,
        'display_name': displayName,
        if (phone != null) 'phone': phone,
        if (email != null) 'email': email,
      };
      final response = await _client
          .from(SupabaseConstants.usersTable)
          .insert(data)
          .select()
          .single();
      return _mapToUserEntity(response as Map<String, dynamic>);
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } on AuthException catch (e) {
      throw AuthFailure(e.message);
    }
  }

  @override
  Future<UserEntity?> getCurrentUser() async {
    final user = _client.auth.currentUser;
    if (user == null) return null;
    try {
      final data = await _client
          .from(SupabaseConstants.usersTable)
          .select()
          .eq('id', user.id)
          .maybeSingle();
      if (data == null) return null;
      return _mapToUserEntity(data as Map<String, dynamic>);
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  @override
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  Future<UserEntity> _getOrCreateUser(User authUser) async {
    final existing = await _client
        .from(SupabaseConstants.usersTable)
        .select()
        .eq('id', authUser.id)
        .maybeSingle();

    if (existing != null) return _mapToUserEntity(existing as Map<String, dynamic>);

    throw const AuthFailure('NEW_USER');
  }

  UserEntity _mapToUserEntity(Map<String, dynamic> data) {
    return UserEntity(
      id: data['id'] as String,
      phone: data['phone'] as String?,
      email: data['email'] as String?,
      username: data['username'] as String,
      displayName: data['display_name'] as String,
      avatarUrl: data['avatar_url'] as String?,
      statusMsg: data['status_msg'] as String? ?? 'Hey there! I am using Chatter.',
      lastSeen: data['last_seen'] != null
          ? DateTime.parse(data['last_seen'] as String)
          : null,
      isOnline: data['is_online'] as bool? ?? false,
      createdAt: DateTime.parse(data['created_at'] as String),
    );
  }
}