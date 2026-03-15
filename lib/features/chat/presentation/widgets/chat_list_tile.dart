import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../domain/entities/chat_entity.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../shared/widgets/user_avatar.dart';

class ChatListTile extends StatelessWidget {
  final ChatEntity chat;
  final VoidCallback onTap;

  const ChatListTile({super.key, required this.chat, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(chat.id),
      background: _SwipeBackground(
        alignment: Alignment.centerLeft,
        color: AppTheme.neutral600,
        icon: Icons.archive_outlined,
        label: 'Archive',
      ),
      secondaryBackground: _SwipeBackground(
        alignment: Alignment.centerRight,
        color: AppTheme.statusError,
        icon: Icons.delete_outline,
        label: 'Delete',
      ),
      confirmDismiss: (direction) async => false, // Handle in production
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: chat.isPinned
                ? AppTheme.brandPrimarySurface.withOpacity(0.5)
                : Colors.white,
            border: const Border(
              bottom: BorderSide(color: Color(0xFFF3F4F6), width: 0.5),
            ),
          ),
          child: Row(
            children: [
              // Avatar
              UserAvatar(
                name: chat.displayName,
                avatarUrl: chat.type == ChatType.direct
                    ? chat.otherUserAvatar
                    : chat.avatarUrl,
                size: 48,
                isOnline: chat.otherUserOnline ?? false,
                isGroup: chat.type == ChatType.group,
              ),
              const SizedBox(width: 12),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (chat.isPinned)
                          const Padding(
                            padding: EdgeInsets.only(right: 4),
                            child: Icon(Icons.push_pin,
                                size: 14, color: AppTheme.neutral400),
                          ),
                        Expanded(
                          child: Text(
                            chat.displayName,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                    color: AppTheme.neutral900,
                                    fontWeight: FontWeight.w600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          chat.lastMessageAt?.chatTimestamp ?? '',
                          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                color: chat.unreadCount > 0
                                    ? AppTheme.brandPrimary
                                    : AppTheme.neutral400,
                                fontWeight: chat.unreadCount > 0
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            chat.lastMessage ?? 'No messages yet',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: chat.isMuted
                                      ? AppTheme.neutral400
                                      : AppTheme.neutral400,
                                ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (chat.isMuted)
                          const Padding(
                            padding: EdgeInsets.only(left: 4),
                            child: Icon(Icons.volume_off,
                                size: 14, color: AppTheme.neutral400),
                          ),
                        if (chat.unreadCount > 0) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: chat.isMuted
                                  ? AppTheme.neutral400
                                  : AppTheme.brandPrimary,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              chat.unreadCount > 99
                                  ? '99+'
                                  : '${chat.unreadCount}',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 200.ms);
  }
}

class _SwipeBackground extends StatelessWidget {
  final AlignmentGeometry alignment;
  final Color color;
  final IconData icon;
  final String label;

  const _SwipeBackground({
    required this.alignment,
    required this.color,
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: color,
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 24),
          const SizedBox(height: 4),
          Text(label,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
