import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../domain/entities/chat_entity.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/extensions.dart';

class MessageBubble extends StatelessWidget {
  final MessageEntity message;
  final bool isSent;
  final VoidCallback onLongPress;
  final VoidCallback onReply;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isSent,
    required this.onLongPress,
    required this.onReply,
  });

  @override
  Widget build(BuildContext context) {
    if (message.isDeleted) {
      return _DeletedBubble(isSent: isSent);
    }

    return GestureDetector(
      onLongPress: onLongPress,
      onHorizontalDragEnd: (d) {
        if (d.primaryVelocity != null &&
            (isSent ? d.primaryVelocity! < -200 : d.primaryVelocity! > 200)) {
          onReply();
        }
      },
      child: Align(
        alignment: isSent ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: EdgeInsets.only(
            left: isSent ? 64 : 12,
            right: isSent ? 12 : 64,
            bottom: 4,
          ),
          child: _buildContent(context),
        ),
      ),
    ).animate().fadeIn(duration: 180.ms).slideX(
          begin: isSent ? 0.1 : -0.1,
          end: 0,
          duration: 200.ms,
          curve: Curves.easeOutCubic,
        );
  }

  Widget _buildContent(BuildContext context) {
    switch (message.type) {
      case MessageType.text:
        return _TextBubble(message: message, isSent: isSent);
      case MessageType.image:
        return _ImageBubble(message: message, isSent: isSent);
      case MessageType.audio:
        return _AudioBubble(message: message, isSent: isSent);
      case MessageType.document:
        return _DocumentBubble(message: message, isSent: isSent);
      default:
        return _TextBubble(message: message, isSent: isSent);
    }
  }
}

class _BubbleContainer extends StatelessWidget {
  final Widget child;
  final bool isSent;
  final EdgeInsets? padding;

  const _BubbleContainer({
    required this.child,
    required this.isSent,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ??
          const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: isSent ? AppTheme.brandPrimarySurface : Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(18),
          topRight: const Radius.circular(18),
          bottomLeft: Radius.circular(isSent ? 18 : 2),
          bottomRight: Radius.circular(isSent ? 2 : 18),
        ),
        border: isSent
            ? null
            : Border.all(color: const Color(0xFFF3F4F6), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _TextBubble extends StatelessWidget {
  final MessageEntity message;
  final bool isSent;

  const _TextBubble({required this.message, required this.isSent});

  @override
  Widget build(BuildContext context) {
    return _BubbleContainer(
      isSent: isSent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            message.content ?? '',
            style: Theme.of(context)
                .textTheme
                .bodyLarge
                ?.copyWith(color: AppTheme.neutral900, height: 1.4),
          ),
          const SizedBox(height: 3),
          _MessageFooter(message: message, isSent: isSent),
        ],
      ),
    );
  }
}

class _ImageBubble extends StatelessWidget {
  final MessageEntity message;
  final bool isSent;

  const _ImageBubble({required this.message, required this.isSent});

  @override
  Widget build(BuildContext context) {
    return _BubbleContainer(
      isSent: isSent,
      padding: const EdgeInsets.all(4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: message.mediaUrl != null
                ? CachedNetworkImage(
                    imageUrl: message.mediaUrl!,
                    width: 200,
                    height: 200,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(
                      width: 200,
                      height: 200,
                      color: AppTheme.neutral100,
                      child: const Center(
                          child: CircularProgressIndicator(
                              color: AppTheme.brandPrimary, strokeWidth: 2)),
                    ),
                    errorWidget: (_, __, ___) => Container(
                      width: 200,
                      height: 200,
                      color: AppTheme.neutral100,
                      child: const Icon(Icons.broken_image_outlined,
                          color: AppTheme.neutral400),
                    ),
                  )
                : Container(
                    width: 200,
                    height: 200,
                    color: AppTheme.neutral100,
                    child: const Icon(Icons.image_outlined,
                        color: AppTheme.neutral400, size: 48),
                  ),
          ),
          if (message.content != null) ...[
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(message.content!,
                  style: Theme.of(context).textTheme.bodyMedium),
            ),
          ],
          Padding(
            padding: const EdgeInsets.only(right: 8, bottom: 4),
            child: _MessageFooter(message: message, isSent: isSent),
          ),
        ],
      ),
    );
  }
}

class _AudioBubble extends StatelessWidget {
  final MessageEntity message;
  final bool isSent;

  const _AudioBubble({required this.message, required this.isSent});

  @override
  Widget build(BuildContext context) {
    return _BubbleContainer(
      isSent: isSent,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: isSent ? AppTheme.brandPrimary : AppTheme.neutral100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.play_arrow_rounded,
              color: isSent ? Colors.white : AppTheme.neutral600,
              size: 22,
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 120,
                height: 2,
                decoration: BoxDecoration(
                  color: isSent
                      ? AppTheme.brandPrimaryDark
                      : AppTheme.neutral400,
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Text('0:00',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: AppTheme.neutral400,
                          )),
                  const Spacer(),
                  _MessageFooter(message: message, isSent: isSent),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DocumentBubble extends StatelessWidget {
  final MessageEntity message;
  final bool isSent;

  const _DocumentBubble({required this.message, required this.isSent});

  @override
  Widget build(BuildContext context) {
    return _BubbleContainer(
      isSent: isSent,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.brandAccentLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.description_outlined,
                color: AppTheme.brandAccent, size: 22),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  message.content ?? 'Document',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.neutral900,
                      ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                _MessageFooter(message: message, isSent: isSent),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DeletedBubble extends StatelessWidget {
  final bool isSent;
  const _DeletedBubble({required this.isSent});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isSent ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(
          left: isSent ? 64 : 12,
          right: isSent ? 12 : 64,
          bottom: 4,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppTheme.neutral100,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFF3F4F6)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.block, size: 14, color: AppTheme.neutral400),
            const SizedBox(width: 6),
            Text(
              isSent ? 'You deleted this message' : 'This message was deleted',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.neutral400,
                    fontStyle: FontStyle.italic,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageFooter extends StatelessWidget {
  final MessageEntity message;
  final bool isSent;

  const _MessageFooter({required this.message, required this.isSent});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          message.createdAt.messageTime,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppTheme.neutral400,
              ),
        ),
        if (isSent) ...[
          const SizedBox(width: 4),
          _TickIcon(status: message.status),
        ],
      ],
    );
  }
}

class _TickIcon extends StatelessWidget {
  final MessageStatus status;
  const _TickIcon({required this.status});

  @override
  Widget build(BuildContext context) {
    switch (status) {
      case MessageStatus.pending:
        return const Icon(Icons.access_time, size: 13, color: AppTheme.neutral400);
      case MessageStatus.sent:
        return const Icon(Icons.done, size: 14, color: AppTheme.neutral400);
      case MessageStatus.delivered:
        return const Icon(Icons.done_all, size: 14, color: AppTheme.neutral400);
      case MessageStatus.read:
        return const Icon(Icons.done_all, size: 14, color: AppTheme.statusInfo);
      case MessageStatus.failed:
        return const Icon(Icons.error_outline, size: 14, color: AppTheme.statusError);
    }
  }
}
