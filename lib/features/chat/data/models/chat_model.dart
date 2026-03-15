import '../../domain/entities/chat_entity.dart';

class ChatModel {
  final String id;
  final String type;
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
  final String? otherUserId;
  final String? otherUserName;
  final String? otherUserAvatar;
  final bool? otherUserOnline;

  const ChatModel({
    required this.id,
    required this.type,
    this.name,
    this.avatarUrl,
    this.lastMessage,
    this.lastMessageAt,
    this.createdBy,
    required this.createdAt,
    required this.participantIds,
    required this.unreadCount,
    required this.isPinned,
    required this.isMuted,
    this.otherUserId,
    this.otherUserName,
    this.otherUserAvatar,
    this.otherUserOnline,
  });

  ChatEntity toEntity() {
    return ChatEntity(
      id: id,
      type: ChatType.values.firstWhere(
        (e) => e.name == type,
        orElse: () => ChatType.direct,
      ),
      name: name,
      avatarUrl: avatarUrl,
      lastMessage: lastMessage,
      lastMessageAt: lastMessageAt,
      createdBy: createdBy,
      createdAt: createdAt,
      participantIds: participantIds,
      unreadCount: unreadCount,
      isPinned: isPinned,
      isMuted: isMuted,
      otherUserId: otherUserId,
      otherUserName: otherUserName,
      otherUserAvatar: otherUserAvatar,
      otherUserOnline: otherUserOnline,
    );
  }

  static ChatModel fromEntity(ChatEntity entity) {
    return ChatModel(
      id: entity.id,
      type: entity.type.name,
      name: entity.name,
      avatarUrl: entity.avatarUrl,
      lastMessage: entity.lastMessage,
      lastMessageAt: entity.lastMessageAt,
      createdBy: entity.createdBy,
      createdAt: entity.createdAt,
      participantIds: List<String>.from(entity.participantIds),
      unreadCount: entity.unreadCount,
      isPinned: entity.isPinned,
      isMuted: entity.isMuted,
      otherUserId: entity.otherUserId,
      otherUserName: entity.otherUserName,
      otherUserAvatar: entity.otherUserAvatar,
      otherUserOnline: entity.otherUserOnline,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'name': name,
        'avatar_url': avatarUrl,
        'last_message': lastMessage,
        'last_message_at': lastMessageAt?.toIso8601String(),
        'created_by': createdBy,
        'created_at': createdAt.toIso8601String(),
        'participant_ids': participantIds,
        'unread_count': unreadCount,
        'is_pinned': isPinned,
        'is_muted': isMuted,
        'other_user_id': otherUserId,
        'other_user_name': otherUserName,
        'other_user_avatar': otherUserAvatar,
        'other_user_online': otherUserOnline,
      };

  static ChatModel fromJson(Map<String, dynamic> json) => ChatModel(
        id: json['id'] as String,
        type: json['type'] as String,
        name: json['name'] as String?,
        avatarUrl: json['avatar_url'] as String?,
        lastMessage: json['last_message'] as String?,
        lastMessageAt: json['last_message_at'] != null
            ? DateTime.parse(json['last_message_at'] as String)
            : null,
        createdBy: json['created_by'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
        participantIds:
            List<String>.from(json['participant_ids'] as List? ?? []),
        unreadCount: json['unread_count'] as int? ?? 0,
        isPinned: json['is_pinned'] as bool? ?? false,
        isMuted: json['is_muted'] as bool? ?? false,
        otherUserId: json['other_user_id'] as String?,
        otherUserName: json['other_user_name'] as String?,
        otherUserAvatar: json['other_user_avatar'] as String?,
        otherUserOnline: json['other_user_online'] as bool?,
      );
}
