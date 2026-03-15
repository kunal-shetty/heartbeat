import '../../../auth/domain/entities/user_entity.dart';
import '../../domain/repositories/profile_repository.dart';
import '../datasources/profile_remote_datasource.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  final ProfileRemoteDataSource _remote;
  ProfileRepositoryImpl(this._remote);

  @override
  Future<UserEntity> getProfile(String userId) => _remote.getProfile(userId);

  @override
  Future<UserEntity> updateProfile({
    required String userId,
    String? displayName,
    String? statusMsg,
    String? avatarPath,
  }) => _remote.updateProfile(
        userId: userId,
        displayName: displayName,
        statusMsg: statusMsg,
        avatarPath: avatarPath,
      );

  @override
  Future<void> updateOnlineStatus({
    required String userId,
    required bool isOnline,
  }) => _remote.updateOnlineStatus(userId: userId, isOnline: isOnline);

  @override
  Future<List<UserEntity>> searchUsers(String query) =>
      _remote.searchUsers(query);
}
