import '../../../auth/domain/entities/user_entity.dart';

abstract class ProfileRepository {
  Future<UserEntity> getProfile(String userId);
  Future<UserEntity> updateProfile({
    required String userId,
    String? displayName,
    String? statusMsg,
    String? avatarPath,
  });
  Future<void> updateOnlineStatus({required String userId, required bool isOnline});
  Future<List<UserEntity>> searchUsers(String query);
}
