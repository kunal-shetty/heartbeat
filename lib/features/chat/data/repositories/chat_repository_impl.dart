import '../../domain/entities/chat_entity.dart';
import '../../domain/repositories/chat_repository.dart';
import '../datasources/chat_remote_datasource.dart';
import '../datasources/chat_local_datasource.dart';
import '../../../../shared/services/connectivity_service.dart';

class ChatRepositoryImpl implements ChatRepository {
  final ChatRemoteDataSource _remote;
  final ChatLocalDataSource _local;
  final ConnectivityService _connectivity;

  ChatRepositoryImpl(this._remote, this._local, this._connectivity);

  @override
  Future<List<ChatEntity>> getChats(String userId) async {
    try {
      final chats = await _remote.getChats(userId);
      await _local.cacheChats(chats);
      return chats;
    } catch (_) {
      return _local.getCachedChats();
    }
  }

  @override
  Stream<List<ChatEntity>> watchChats(String userId) =>
      _remote.watchChats(userId);

  @override
  Future<ChatEntity> createDirectChat({
    required String currentUserId,
    required String otherUserId,
  }) => _remote.createDirectChat(
        currentUserId: currentUserId,
        otherUserId: otherUserId,
      );

  @override
  Future<ChatEntity> createGroupChat({
    required String createdBy,
    required String name,
    required List<String> participantIds,
    String? avatarUrl,
    String? description,
  }) => _remote.createGroupChat(
        createdBy: createdBy,
        name: name,
        participantIds: participantIds,
        avatarUrl: avatarUrl,
        description: description,
      );

  @override
  Future<List<MessageEntity>> getMessages({
    required String chatId,
    int limit = 30,
    String? before,
  }) async {
    try {
      final messages =
          await _remote.getMessages(chatId: chatId, limit: limit, before: before);
      await _local.cacheMessages(messages);
      return messages;
    } catch (_) {
      return _local.getCachedMessages(chatId);
    }
  }

  @override
  Stream<MessageEntity> watchNewMessages(String chatId) =>
      _remote.watchNewMessages(chatId);

  @override
  Future<MessageEntity> sendMessage({
    required String chatId,
    required String senderId,
    required String? content,
    required MessageType type,
    String? mediaUrl,
    String? replyToId,
  }) async {
    // Optimistic: cache immediately as pending
    final optimistic = MessageEntity(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      chatId: chatId,
      senderId: senderId,
      content: content,
      type: type,
      mediaUrl: mediaUrl,
      replyToId: replyToId,
      status: MessageStatus.pending,
      createdAt: DateTime.now(),
    );
    await _local.cacheMessage(optimistic);

    try {
      final sent = await _remote.sendMessage(
        chatId: chatId,
        senderId: senderId,
        content: content,
        type: type,
        mediaUrl: mediaUrl,
        replyToId: replyToId,
      );
      await _local.deleteMessage(optimistic.id);
      await _local.cacheMessage(sent);
      return sent;
    } catch (e) {
      // Keep as pending for retry
      rethrow;
    }
  }

  @override
  Future<void> deleteMessage({
    required String messageId,
    required bool deleteForEveryone,
  }) async {
    await _remote.deleteMessage(
        messageId: messageId, deleteForEveryone: deleteForEveryone);
    await _local.deleteMessage(messageId);
  }

  @override
  Future<void> markMessagesRead({
    required String chatId,
    required String userId,
  }) => _remote.markMessagesRead(chatId: chatId, userId: userId);

  @override
  Future<void> sendTypingIndicator({
    required String chatId,
    required String userId,
    required bool isTyping,
  }) => _remote.sendTypingIndicator(
        chatId: chatId, userId: userId, isTyping: isTyping);

  @override
  Stream<List<String>> watchTypingUsers(String chatId) =>
      _remote.watchTypingUsers(chatId);

  @override
  Future<void> updateOnlineStatus({
    required String userId,
    required bool isOnline,
  }) async {
    // Handled via Supabase presence
  }

  @override
  Future<String> uploadMedia({
    required String chatId,
    required String filePath,
    required String fileName,
    required String mimeType,
  }) => _remote.uploadMedia(
        chatId: chatId,
        filePath: filePath,
        fileName: fileName,
        mimeType: mimeType,
      );
}
