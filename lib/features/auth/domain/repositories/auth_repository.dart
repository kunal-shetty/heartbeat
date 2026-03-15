import 'package:supabase_flutter/supabase_flutter.dart' show User;
import '../entities/user_entity.dart';

abstract class AuthRepository {
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
  Stream<User?> get authStateChanges;
}
