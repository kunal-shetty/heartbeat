import '../entities/chat_entity.dart';

abstract class ChatRepository {
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

  Future<void> markMessagesRead({
    required String chatId,
    required String userId,
  });

  Future<void> sendTypingIndicator({
    required String chatId,
    required String userId,
    required bool isTyping,
  });

  Stream<List<String>> watchTypingUsers(String chatId);

  Future<void> updateOnlineStatus({
    required String userId,
    required bool isOnline,
  });

  Future<String> uploadMedia({
    required String chatId,
    required String filePath,
    required String fileName,
    required String mimeType,
  });
}
