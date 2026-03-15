import '../entities/chat_entity.dart';
import '../repositories/chat_repository.dart';

class GetChats {
  final ChatRepository repository;
  GetChats(this.repository);
  Future<List<ChatEntity>> call(String userId) => repository.getChats(userId);
  Stream<List<ChatEntity>> watch(String userId) => repository.watchChats(userId);
}

class GetMessages {
  final ChatRepository repository;
  GetMessages(this.repository);
  Future<List<MessageEntity>> call({
    required String chatId,
    int limit = 30,
    String? before,
  }) => repository.getMessages(chatId: chatId, limit: limit, before: before);

  Stream<MessageEntity> watch(String chatId) => repository.watchNewMessages(chatId);
}

class SendMessage {
  final ChatRepository repository;
  SendMessage(this.repository);
  Future<MessageEntity> call({
    required String chatId,
    required String senderId,
    required String? content,
    required MessageType type,
    String? mediaUrl,
    String? replyToId,
  }) => repository.sendMessage(
        chatId: chatId,
        senderId: senderId,
        content: content,
        type: type,
        mediaUrl: mediaUrl,
        replyToId: replyToId,
      );
}

class DeleteMessage {
  final ChatRepository repository;
  DeleteMessage(this.repository);
  Future<void> call({required String messageId, bool deleteForEveryone = false}) =>
      repository.deleteMessage(
          messageId: messageId, deleteForEveryone: deleteForEveryone);
}

class MarkMessagesRead {
  final ChatRepository repository;
  MarkMessagesRead(this.repository);
  Future<void> call({required String chatId, required String userId}) =>
      repository.markMessagesRead(chatId: chatId, userId: userId);
}

class CreateDirectChat {
  final ChatRepository repository;
  CreateDirectChat(this.repository);
  Future<ChatEntity> call({
    required String currentUserId,
    required String otherUserId,
  }) => repository.createDirectChat(
        currentUserId: currentUserId,
        otherUserId: otherUserId,
      );
}
