import '../../../auth/domain/entities/user_entity.dart';
import '../repositories/profile_repository.dart';

class GetProfile {
  final ProfileRepository repository;
  GetProfile(this.repository);
  Future<UserEntity> call(String userId) => repository.getProfile(userId);
}

class UpdateProfile {
  final ProfileRepository repository;
  UpdateProfile(this.repository);
  Future<UserEntity> call({
    required String userId,
    String? displayName,
    String? statusMsg,
    String? avatarPath,
  }) => repository.updateProfile(
        userId: userId,
        displayName: displayName,
        statusMsg: statusMsg,
        avatarPath: avatarPath,
      );
}
