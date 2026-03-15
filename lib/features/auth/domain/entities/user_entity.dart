import 'package:equatable/equatable.dart';

class UserEntity extends Equatable {
  final String id;
  final String? phone;
  final String? email;
  final String username;
  final String displayName;
  final String? avatarUrl;
  final String statusMsg;
  final DateTime? lastSeen;
  final bool isOnline;
  final DateTime createdAt;

  const UserEntity({
    required this.id,
    this.phone,
    this.email,
    required this.username,
    required this.displayName,
    this.avatarUrl,
    this.statusMsg = 'Hey there! I am using Chatter.',
    this.lastSeen,
    this.isOnline = false,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
        id, phone, email, username, displayName,
        avatarUrl, statusMsg, lastSeen, isOnline, createdAt,
      ];

  UserEntity copyWith({
    String? displayName,
    String? avatarUrl,
    String? statusMsg,
    bool? isOnline,
    DateTime? lastSeen,
  }) {
    return UserEntity(
      id: id,
      phone: phone,
      email: email,
      username: username,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      statusMsg: statusMsg ?? this.statusMsg,
      lastSeen: lastSeen ?? this.lastSeen,
      isOnline: isOnline ?? this.isOnline,
      createdAt: createdAt,
    );
  }
}
