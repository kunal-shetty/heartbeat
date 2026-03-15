import '../../domain/entities/chat_entity.dart';

class MessageModel {
  final String id;
  final String chatId;
  final String senderId;
  final String? content;
  final String type;
  final String? mediaUrl;
  final String? replyToId;
  final bool isDeleted;
  final String status;
  final DateTime createdAt;

  const MessageModel({
    required this.id,
    required this.chatId,
    required this.senderId,
    this.content,
    required this.type,
    this.mediaUrl,
    this.replyToId,
    required this.isDeleted,
    required this.status,
    required this.createdAt,
  });

  MessageEntity toEntity() {
    return MessageEntity(
      id: id,
      chatId: chatId,
      senderId: senderId,
      content: content,
      type: MessageType.values.firstWhere(
        (e) => e.name == type,
        orElse: () => MessageType.text,
      ),
      mediaUrl: mediaUrl,
      replyToId: replyToId,
      isDeleted: isDeleted,
      status: MessageStatus.values.firstWhere(
        (e) => e.name == status,
        orElse: () => MessageStatus.sent,
      ),
      createdAt: createdAt,
    );
  }

  static MessageModel fromEntity(MessageEntity entity) {
    return MessageModel(
      id: entity.id,
      chatId: entity.chatId,
      senderId: entity.senderId,
      content: entity.content,
      type: entity.type.name,
      mediaUrl: entity.mediaUrl,
      replyToId: entity.replyToId,
      isDeleted: entity.isDeleted,
      status: entity.status.name,
      createdAt: entity.createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'chat_id': chatId,
        'sender_id': senderId,
        'content': content,
        'type': type,
        'media_url': mediaUrl,
        'reply_to_id': replyToId,
        'is_deleted': isDeleted,
        'status': status,
        'created_at': createdAt.toIso8601String(),
      };

  static MessageModel fromJson(Map<String, dynamic> json) => MessageModel(
        id: json['id'] as String,
        chatId: json['chat_id'] as String,
        senderId: json['sender_id'] as String,
        content: json['content'] as String?,
        type: json['type'] as String,
        mediaUrl: json['media_url'] as String?,
        replyToId: json['reply_to_id'] as String?,
        isDeleted: json['is_deleted'] as bool? ?? false,
        status: json['status'] as String? ?? 'sent',
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}
