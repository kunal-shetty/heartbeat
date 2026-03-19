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

      // Only attempt upload if a local file path was given
      if (avatarPath != null && avatarPath.isNotEmpty) {
        try {
          final file = File(avatarPath);
          final ext = avatarPath.split('.').last.toLowerCase();
          final storagePath = '$userId/avatar.$ext';

          await _client.storage
              .from(SupabaseConstants.avatarsBucket)
              .upload(storagePath, file,
                  fileOptions: const FileOptions(
                      upsert: true, contentType: 'image/jpeg'));

          // Public URL with a cache-bust so the new image is shown immediately
          avatarUrl =
              '${_client.storage.from(SupabaseConstants.avatarsBucket).getPublicUrl(storagePath)}'
              '?t=${DateTime.now().millisecondsSinceEpoch}';
        } catch (uploadErr) {
          // Log upload error but continue saving other fields
          // The error message shown to user is handled in the UI layer
          final msg = uploadErr.toString().toLowerCase();
          if (msg.contains('policy') ||
              msg.contains('permission') ||
              msg.contains('rls')) {
            throw ServerFailure(
                'Photo upload blocked — please run the database migration first.');
          }
          throw ServerFailure('Photo upload failed. Check your connection.');
        }
      }

      final updates = <String, dynamic>{
        if (displayName != null && displayName.isNotEmpty)
          'display_name': displayName,
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
    } on ServerFailure {
      rethrow;
    } catch (e) {
      // Don't expose raw Supabase exception — clean message only
      final msg = e.toString().toLowerCase();
      if (msg.contains('network') || msg.contains('socket')) {
        throw ServerFailure('No internet connection. Please try again.');
      }
      throw ServerFailure('Could not save profile. Please try again.');
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
