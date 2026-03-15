import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

class SignInWithPhone {
  final AuthRepository repository;
  SignInWithPhone(this.repository);
  Future<void> call(String phone) => repository.signInWithPhone(phone);
}

class VerifyOtp {
  final AuthRepository repository;
  VerifyOtp(this.repository);
  Future<UserEntity> call({required String phone, required String token}) =>
      repository.verifyOtp(phone: phone, token: token);
}

class SignInWithEmail {
  final AuthRepository repository;
  SignInWithEmail(this.repository);
  Future<UserEntity> call({required String email, required String password}) =>
      repository.signInWithEmail(email: email, password: password);
}

class SignInWithGoogle {
  final AuthRepository repository;
  SignInWithGoogle(this.repository);
  Future<void> call() => repository.signInWithGoogle();
}

class SignOut {
  final AuthRepository repository;
  SignOut(this.repository);
  Future<void> call() => repository.signOut();
}

class GetCurrentUser {
  final AuthRepository repository;
  GetCurrentUser(this.repository);
  Future<UserEntity?> call() => repository.getCurrentUser();
}
