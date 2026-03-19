import 'package:supabase_flutter/supabase_flutter.dart' show User;
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remote;

  AuthRepositoryImpl(this._remote);

  @override
  Future<void> signInWithPhone(String phone) => _remote.signInWithPhone(phone);

  @override
  Future<UserEntity> verifyOtp({required String phone, required String token}) =>
      _remote.verifyOtp(phone: phone, token: token);
@override
Future<void> signUpWithEmail({
  required String email,
  required String password,
  required String username,
  required String displayName,
}) => _remote.signUpWithEmail(
      email: email,
      password: password,
      username: username,
      displayName: displayName,
    );
    
  @override
  Future<UserEntity> signInWithEmail({required String email, required String password}) =>
      _remote.signInWithEmail(email: email, password: password);

  @override
  Future<void> signInWithGoogle() => _remote.signInWithGoogle();

  @override
  Future<UserEntity> registerUser({
    required String userId,
    required String username,
    required String displayName,
    String? phone,
    String? email,
  }) => _remote.registerUser(
        userId: userId,
        username: username,
        displayName: displayName,
        phone: phone,
        email: email,
      );


  @override
  Future<void> signOut() => _remote.signOut();

  @override
  Future<UserEntity?> getCurrentUser() => _remote.getCurrentUser();

  @override
  Stream<User?> get authStateChanges =>
      _remote.authStateChanges.map((state) => state.session?.user);
}
