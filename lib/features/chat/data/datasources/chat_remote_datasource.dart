import 'dart:async';
import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/chat_entity.dart';
import '../../../../core/constants/supabase_constants.dart';
import '../../../../core/errors/failure.dart';

abstract class ChatRemoteDataSource {
  Future<List<ChatEntity>> getChats(String userId);
  Stream<List<ChatEntity>> watchChats(String userId);
  Future<ChatEntity> createDirectChat({
    required String currentUserId,
    required String otherUserId,
  });
  Future<ChatEntity> createGroupChat({
    required String createdBy,
    required String name,
    required List<String> participantIds,
    String? avatarUrl,
    String? description,
  });
  Future<List<MessageEntity>> getMessages({
    required String chatId,
    int limit = 30,
    String? before,
  });
  Stream<MessageEntity> watchNewMessages(String chatId);
  Future<MessageEntity> sendMessage({
    required String chatId,
    required String senderId,
    required String? content,
    required MessageType type,
    String? mediaUrl,
    String? replyToId,
  });
  Future<void> deleteMessage({
    required String messageId,
    required bool deleteForEveryone,
  });
  Future<void> markMessagesRead({required String chatId, required String userId});
  Future<void> sendTypingIndicator({
    required String chatId,
    required String userId,
    required bool isTyping,
  });
  Stream<List<String>> watchTypingUsers(String chatId);
  Future<String> uploadMedia({
    required String chatId,
    required String filePath,
    required String fileName,
    required String mimeType,
  });
}

class ChatRemoteDataSourceImpl implements ChatRemoteDataSource {
  final SupabaseClient _client;
  final _uuid = const Uuid();
  final Map<String, RealtimeChannel> _channels = {};

  ChatRemoteDataSourceImpl(this._client);

  // ── Chats ─────────────────────────────────────────────────────────────────

  @override
  Future<List<ChatEntity>> getChats(String userId) async {
    try {
      final data = await _client
          .from(SupabaseConstants.chatsTable)
          .select('''
            *,
            chat_participants!inner(user_id),
            participants:chat_participants(
              user:users(id, display_name, avatar_url, is_online)
            )
          ''')
          .eq('chat_participants.user_id', userId)
          .order('last_msg_at', ascending: false);

      return (data as List)
          .map((d) => _mapChat(d as Map<String, dynamic>, userId))
          .toList();
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  @override
  Stream<List<ChatEntity>> watchChats(String userId) {
    final controller = StreamController<List<ChatEntity>>.broadcast();

    _client
        .channel('chats:$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: SupabaseConstants.chatsTable,
          callback: (_) async {
            final chats = await getChats(userId);
            if (!controller.isClosed) controller.add(chats);
          },
        )
        .subscribe();

    return controller.stream;
  }

  @override
  Future<ChatEntity> createDirectChat({
    required String currentUserId,
    required String otherUserId,
  }) async {
    try {
      // Check if direct chat already exists
      final existing = await _client.rpc('get_direct_chat', params: {
        'user1_id': currentUserId,
        'user2_id': otherUserId,
      });
      if (existing != null) {
        return _mapChat(existing as Map<String, dynamic>, currentUserId);
      }

      // Create new chat
      final chatData = await _client
          .from(SupabaseConstants.chatsTable)
          .insert({'type': 'direct', 'created_by': currentUserId})
          .select()
          .single();

      await _client.from(SupabaseConstants.chatParticipantsTable).insert([
        {'chat_id': chatData['id'], 'user_id': currentUserId, 'role': 'member'},
        {'chat_id': chatData['id'], 'user_id': otherUserId, 'role': 'member'},
      ]);

      final full = await _client
          .from(SupabaseConstants.chatsTable)
          .select('''
            *,
            participants:chat_participants(
              user:users(id, display_name, avatar_url, is_online)
            )
          ''')
          .eq('id', chatData['id'] as String)
          .single();

      return _mapChat(full as Map<String, dynamic>, currentUserId);
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  @override
  Future<ChatEntity> createGroupChat({
    required String createdBy,
    required String name,
    required List<String> participantIds,
    String? avatarUrl,
    String? description,
  }) async {
    try {
      final chatData = await _client
          .from(SupabaseConstants.chatsTable)
          .insert({
            'type': 'group',
            'name': name,
            'avatar_url': avatarUrl,
            'created_by': createdBy,
          })
          .select()
          .single();

      final allIds = {createdBy, ...participantIds};
      final participants = allIds
          .map((uid) => {
                'chat_id': chatData['id'],
                'user_id': uid,
                'role': uid == createdBy ? 'admin' : 'member',
              })
          .toList();

      await _client.from(SupabaseConstants.chatParticipantsTable).insert(participants);
      return _mapChat(chatData as Map<String, dynamic>, createdBy);
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  // ── Messages ──────────────────────────────────────────────────────────────

  @override
  Future<List<MessageEntity>> getMessages({
    required String chatId,
    int limit = 30,
    String? before,
  }) async {
    try {
      // Build base query
      var query = _client
          .from(SupabaseConstants.messagesTable)
          .select('*')
          .eq('chat_id', chatId)
          .eq('is_deleted', false)
          .order('created_at', ascending: false)
          .limit(limit);

      // Apply cursor filter separately when needed
      final List<Map<String, dynamic>> data;
      if (before != null) {
        final result = await _client
            .from(SupabaseConstants.messagesTable)
            .select('*')
            .eq('chat_id', chatId)
            .eq('is_deleted', false)
            .lt('created_at', before)
            .order('created_at', ascending: false)
            .limit(limit);
        data = List<Map<String, dynamic>>.from(result as List);
      } else {
        final result = await query;
        data = List<Map<String, dynamic>>.from(result as List);
      }

      return data.map(_mapMessage).toList().reversed.toList();
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  @override
  Stream<MessageEntity> watchNewMessages(String chatId) {
    final controller = StreamController<MessageEntity>.broadcast();

    final channel = _client
        .channel(SupabaseConstants.chatChannel(chatId))
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: SupabaseConstants.messagesTable,
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'chat_id',
            value: chatId,
          ),
          callback: (payload) {
            final message = _mapMessage(
                Map<String, dynamic>.from(payload.newRecord));
            if (!controller.isClosed) controller.add(message);
          },
        )
        .subscribe();

    _channels[chatId] = channel;
    return controller.stream;
  }

  @override
  Future<MessageEntity> sendMessage({
    required String chatId,
    required String senderId,
    required String? content,
    required MessageType type,
    String? mediaUrl,
    String? replyToId,
  }) async {
    try {
      final data = await _client
          .from(SupabaseConstants.messagesTable)
          .insert({
            'chat_id': chatId,
            'sender_id': senderId,
            'content': content,
            'type': type.name,
            'media_url': mediaUrl,
            'reply_to_id': replyToId,
          })
          .select()
          .single();

      await _client.from(SupabaseConstants.chatsTable).update({
        'last_message': content ?? '[${type.name}]',
        'last_msg_at': data['created_at'],
      }).eq('id', chatId);

      return _mapMessage(data as Map<String, dynamic>);
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  @override
  Future<void> deleteMessage({
    required String messageId,
    required bool deleteForEveryone,
  }) async {
    try {
      if (deleteForEveryone) {
        await _client
            .from(SupabaseConstants.messagesTable)
            .update({'is_deleted': true, 'content': null, 'media_url': null})
            .eq('id', messageId);
      }
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  @override
  Future<void> markMessagesRead({
    required String chatId,
    required String userId,
  }) async {
    try {
      final messages = await _client
          .from(SupabaseConstants.messagesTable)
          .select('id')
          .eq('chat_id', chatId)
          .neq('sender_id', userId);

      final list = messages as List;
      if (list.isEmpty) return;

      final statusRows = list
          .map((m) => {
                'message_id': (m as Map<String, dynamic>)['id'],
                'user_id': userId,
                'status': 'read',
              })
          .toList();

      await _client
          .from(SupabaseConstants.messageStatusTable)
          .upsert(statusRows, onConflict: 'message_id,user_id');
    } catch (_) {
      // Non-critical
    }
  }

  // ── Presence / Typing ─────────────────────────────────────────────────────

  @override
  Future<void> sendTypingIndicator({
    required String chatId,
    required String userId,
    required bool isTyping,
  }) async {
    try {
      final channel = _client.channel(SupabaseConstants.presenceChannel(chatId));
      await channel.track({'user_id': userId, 'typing': isTyping});
    } catch (_) {}
  }

  @override
Stream<List<String>> watchTypingUsers(String chatId) {
  final controller = StreamController<List<String>>.broadcast();

  final channel = _client.channel(SupabaseConstants.presenceChannel(chatId));

  channel
      .onPresenceSync((_) {
        try {
          // presenceState() returns List<dynamic> — cast each item to
          // Presence (from supabase_flutter) which has .payload
          final presences = channel.presenceState();
          final typing = <String>[];
          for (final item in presences) {
            final data = (item as Presence).payload;
            if (data['typing'] == true) {
              final userId = data['user_id']?.toString();
              if (userId != null && userId.isNotEmpty) {
                typing.add(userId);
              }
            }
          }
          if (!controller.isClosed) controller.add(typing);
        } catch (_) {}
      })
      .subscribe();

  return controller.stream;
}

  // ── Media ─────────────────────────────────────────────────────────────────

  @override
  Future<String> uploadMedia({
    required String chatId,
    required String filePath,
    required String fileName,
    required String mimeType,
  }) async {
    try {
      final ext = fileName.split('.').last;
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

  void unsubscribe(String chatId) {
    _channels[chatId]?.unsubscribe();
    _channels.remove(chatId);
  }

  // ── Mappers ───────────────────────────────────────────────────────────────

  MessageEntity _mapMessage(Map<String, dynamic> data) {
    return MessageEntity(
      id: data['id'] as String,
      chatId: data['chat_id'] as String,
      senderId: data['sender_id'] as String,
      content: data['content'] as String?,
      type: MessageType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => MessageType.text,
      ),
      mediaUrl: data['media_url'] as String?,
      replyToId: data['reply_to_id'] as String?,
      isDeleted: data['is_deleted'] as bool? ?? false,
      status: MessageStatus.sent,
      createdAt: DateTime.parse(data['created_at'] as String),
    );
  }

  ChatEntity _mapChat(Map<String, dynamic> data, String currentUserId) {
    final participants =
        (data['participants'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final participantIds = participants
        .map((p) => (p['user'] as Map<String, dynamic>)['id'] as String)
        .toList();

    String? otherUserId, otherUserName, otherUserAvatar;
    bool? otherUserOnline;

    if (data['type'] == 'direct') {
      final others = participants.where(
        (p) => (p['user'] as Map<String, dynamic>)['id'] != currentUserId,
      );
      if (others.isNotEmpty) {
        final other = others.first['user'] as Map<String, dynamic>;
        otherUserId = other['id'] as String?;
        otherUserName = other['display_name'] as String?;
        otherUserAvatar = other['avatar_url'] as String?;
        otherUserOnline = other['is_online'] as bool?;
      }
    }

    return ChatEntity(
      id: data['id'] as String,
      type: data['type'] == 'group' ? ChatType.group : ChatType.direct,
      name: data['name'] as String?,
      avatarUrl: data['avatar_url'] as String?,
      lastMessage: data['last_message'] as String?,
      lastMessageAt: data['last_msg_at'] != null
          ? DateTime.parse(data['last_msg_at'] as String)
          : null,
      createdBy: data['created_by'] as String?,
      createdAt: DateTime.parse(data['created_at'] as String),
      participantIds: participantIds,
      otherUserId: otherUserId,
      otherUserName: otherUserName,
      otherUserAvatar: otherUserAvatar,
      otherUserOnline: otherUserOnline,
    );
  }
}
