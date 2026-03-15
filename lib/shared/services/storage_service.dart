import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../core/constants/supabase_constants.dart';
import '../../core/errors/failure.dart';

class StorageService {
  final SupabaseClient _client;
  final _uuid = const Uuid();

  StorageService(this._client);

  Future<String> uploadAvatar({
    required String userId,
    required String filePath,
  }) async {
    try {
      final ext = filePath.split('.').last;
      final path = '$userId/avatar.$ext';
      await _client.storage
          .from(SupabaseConstants.avatarsBucket)
          .upload(path, File(filePath),
              fileOptions: const FileOptions(upsert: true));
      return _client.storage
          .from(SupabaseConstants.avatarsBucket)
          .getPublicUrl(path);
    } catch (e) {
      throw MediaFailure(e.toString());
    }
  }

  Future<String> uploadChatMedia({
    required String chatId,
    required String filePath,
    required String mimeType,
  }) async {
    try {
      final ext = filePath.split('.').last;
      final path = '$chatId/${_uuid.v4()}.$ext';
      await _client.storage
          .from(SupabaseConstants.chatMediaBucket)
          .upload(path, File(filePath),
              fileOptions: FileOptions(contentType: mimeType));
      return await _client.storage
          .from(SupabaseConstants.chatMediaBucket)
          .createSignedUrl(path, 3600);
    } catch (e) {
      throw MediaFailure(e.toString());
    }
  }

  Future<String> uploadGroupIcon({
    required String groupId,
    required String filePath,
  }) async {
    try {
      final ext = filePath.split('.').last;
      final path = '$groupId/icon.$ext';
      await _client.storage
          .from(SupabaseConstants.groupIconsBucket)
          .upload(path, File(filePath),
              fileOptions: const FileOptions(upsert: true));
      return _client.storage
          .from(SupabaseConstants.groupIconsBucket)
          .getPublicUrl(path);
    } catch (e) {
      throw MediaFailure(e.toString());
    }
  }

  Future<void> deleteFile({
    required String bucket,
    required String path,
  }) async {
    await _client.storage.from(bucket).remove([path]);
  }
}
