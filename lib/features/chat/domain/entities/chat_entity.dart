import 'package:equatable/equatable.dart';

enum MessageType { text, image, video, audio, document, location }
enum MessageStatus { pending, sent, delivered, read, failed }

class MessageEntity extends Equatable {
  final String id;
  final String chatId;
  final String senderId;
  final String? content;
  final MessageType type;
  final String? mediaUrl;
  final String? replyToId;
  final MessageEntity? replyTo;
  final bool isDeleted;
  final MessageStatus status;
  final DateTime createdAt;

  const MessageEntity({
    required this.id,
    required this.chatId,
    required this.senderId,
    this.content,
    required this.type,
    this.mediaUrl,
    this.replyToId,
    this.replyTo,
    this.isDeleted = false,
    this.status = MessageStatus.sent,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
        id, chatId, senderId, content, type,
        mediaUrl, replyToId, isDeleted, status, createdAt,
      ];

  MessageEntity copyWith({
    MessageStatus? status,
    bool? isDeleted,
    String? mediaUrl,
  }) {
    return MessageEntity(
      id: id,
      chatId: chatId,
      senderId: senderId,
      content: content,
      type: type,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      replyToId: replyToId,
      replyTo: replyTo,
      isDeleted: isDeleted ?? this.isDeleted,
      status: status ?? this.status,
      createdAt: createdAt,
    );
  }
}

enum ChatType { direct, group }

class ChatEntity extends Equatable {
  final String id;
  final ChatType type;
  final String? name;
  final String? avatarUrl;
  final String? lastMessage;
  final DateTime? lastMessageAt;
  final String? createdBy;
  final DateTime createdAt;
  final List<String> participantIds;
  final int unreadCount;
  final bool isPinned;
  final bool isMuted;

  // For direct chats – the other participant's info
  final String? otherUserId;
  final String? otherUserName;
  final String? otherUserAvatar;
  final bool? otherUserOnline;

  const ChatEntity({
    required this.id,
    required this.type,
    this.name,
    this.avatarUrl,
    this.lastMessage,
    this.lastMessageAt,
    this.createdBy,
    required this.createdAt,
    this.participantIds = const [],
    this.unreadCount = 0,
    this.isPinned = false,
    this.isMuted = false,
    this.otherUserId,
    this.otherUserName,
    this.otherUserAvatar,
    this.otherUserOnline,
  });

  String get displayName {
    if (type == ChatType.direct) return otherUserName ?? 'Unknown';
    return name ?? 'Group Chat';
  }

  @override
  List<Object?> get props => [
        id, type, name, avatarUrl, lastMessage,
        lastMessageAt, participantIds, unreadCount, isPinned,
      ];
}
