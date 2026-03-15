import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../../core/constants/supabase_constants.dart';
import '../../../../core/errors/failure.dart';

abstract class ProfileRemoteDataSource {
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

class ProfileRemoteDataSourceImpl implements ProfileRemoteDataSource {
  final SupabaseClient _client;
  ProfileRemoteDataSourceImpl(this._client);

  @override
  Future<UserEntity> getProfile(String userId) async {
    try {
      final data = await _client
          .from(SupabaseConstants.usersTable)
          .select()
          .eq('id', userId)
          .single();
      return _map(data);
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  @override
  Future<UserEntity> updateProfile({
    required String userId,
    String? displayName,
    String? statusMsg,
    String? avatarPath,
  }) async {
    try {
      String? avatarUrl;

      if (avatarPath != null) {
        final ext = avatarPath.split('.').last;
        final path = '$userId/avatar.$ext';
        await _client.storage
            .from(SupabaseConstants.avatarsBucket)
            .upload(path, File(avatarPath),
                fileOptions: const FileOptions(upsert: true));
        avatarUrl = _client.storage
            .from(SupabaseConstants.avatarsBucket)
            .getPublicUrl(path);
      }

      final updates = <String, dynamic>{
        if (displayName != null) 'display_name': displayName,
        if (statusMsg != null) 'status_msg': statusMsg,
        if (avatarUrl != null) 'avatar_url': avatarUrl,
      };

      if (updates.isEmpty) return getProfile(userId);

      final data = await _client
          .from(SupabaseConstants.usersTable)
          .update(updates)
          .eq('id', userId)
          .select()
          .single();
      return _map(data);
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  @override
  Future<void> updateOnlineStatus({
    required String userId,
    required bool isOnline,
  }) async {
    await _client.from(SupabaseConstants.usersTable).update({
      'is_online': isOnline,
      'last_seen': DateTime.now().toIso8601String(),
    }).eq('id', userId);
  }

  @override
  Future<List<UserEntity>> searchUsers(String query) async {
    try {
      final data = await _client
          .from(SupabaseConstants.usersTable)
          .select()
          .or('display_name.ilike.%$query%,username.ilike.%$query%')
          .limit(20);
      return (data as List)
          .map((e) => _map(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  UserEntity _map(Map<String, dynamic> data) => UserEntity(
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
