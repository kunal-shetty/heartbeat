import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../features/auth/presentation/blocs/auth_bloc.dart';
import '../blocs/chat_bloc.dart';
import '../../domain/entities/chat_entity.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../injection_container.dart' as di;
import '../widgets/message_bubble.dart';
import '../widgets/message_input_bar.dart';
import '../widgets/typing_indicator.dart';
import '../../../../shared/widgets/user_avatar.dart';

class ChatScreen extends StatefulWidget {
  final String chatId;
  final Map<String, dynamic>? chatData;

  const ChatScreen({super.key, required this.chatId, this.chatData});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late final ChatBloc _chatBloc;
  final _scrollController = ScrollController();
  String _currentUserId = '';

  @override
  void initState() {
    super.initState();
    _chatBloc = di.sl<ChatBloc>();

    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticatedState) {
      _currentUserId = authState.user.id;
      _chatBloc.add(ChatLoadEvent(
        chatId: widget.chatId,
        currentUserId: _currentUserId,
      ));
    }

    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels <=
        _scrollController.position.minScrollExtent + 200) {
      _chatBloc.add(ChatLoadMoreEvent(widget.chatId));
    }
  }

  void _scrollToBottom({bool animated = true}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        if (animated) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        } else {
          _scrollController.jumpTo(
              _scrollController.position.maxScrollExtent);
        }
      }
    });
  }

  @override
  void dispose() {
    _chatBloc.close();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chatName = widget.chatData?['chatName'] as String? ?? 'Chat';
    final isOnline = widget.chatData?['isOnline'] as bool? ?? false;
    final isGroup = widget.chatData?['isGroup'] as bool? ?? false;

    return BlocProvider.value(
      value: _chatBloc,
      child: Scaffold(
        backgroundColor: AppTheme.neutral100,
        appBar: _ChatAppBar(
          chatName: chatName,
          chatId: widget.chatId,
          chatData: widget.chatData,
          isOnline: isOnline,
          isGroup: isGroup,
        ),
        body: BlocConsumer<ChatBloc, ChatState>(
          listener: (context, state) {
            if (state is ChatLoadedState) {
              _scrollToBottom();
            }
          },
          builder: (context, state) {
            if (state is ChatLoadingState) {
              return const Center(
                child: CircularProgressIndicator(color: AppTheme.brandPrimary),
              );
            }

            if (state is ChatErrorState) {
              return Center(child: Text(state.message));
            }

            if (state is ChatLoadedState) {
              return Column(
                children: [
                  // Reply preview
                  if (state.replyToMessage != null)
                    _ReplyPreview(
                      message: state.replyToMessage!,
                      onCancel: () => _chatBloc.add(ChatSetReplyEvent(null)),
                    ),
                  // Messages
                  Expanded(
                    child: _MessageList(
                      messages: state.messages,
                      currentUserId: _currentUserId,
                      scrollController: _scrollController,
                      chatBloc: _chatBloc,
                      chatId: widget.chatId,
                    ),
                  ),
                  // Typing indicator
                  if (state.typingUserIds.isNotEmpty)
                    const TypingIndicator(),
                  // Input
                  MessageInputBar(
                    onSendText: (text) {
                      _chatBloc.add(ChatSendMessageEvent(
                        chatId: widget.chatId,
                        senderId: _currentUserId,
                        content: text,
                        type: MessageType.text,
                        replyToId: state.replyToMessage?.id,
                      ));
                      _scrollToBottom();
                    },
                    onSendMedia: (path, type) {
                      _chatBloc.add(ChatSendMessageEvent(
                        chatId: widget.chatId,
                        senderId: _currentUserId,
                        content: null,
                        type: type,
                        mediaUrl: path,
                      ));
                    },
                    onTyping: (isTyping) {
                      _chatBloc.add(ChatTypingEvent(
                        chatId: widget.chatId,
                        userId: _currentUserId,
                        isTyping: isTyping,
                      ));
                    },
                  ),
                ],
              );
            }
            return const SizedBox();
          },
        ),
      ),
    );
  }
}

class _ChatAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String chatName, chatId;
  final Map<String, dynamic>? chatData;
  final bool isOnline, isGroup;

  const _ChatAppBar({
    required this.chatName,
    required this.chatId,
    required this.chatData,
    required this.isOnline,
    required this.isGroup,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      titleSpacing: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => context.pop(),
      ),
      title: InkWell(
        onTap: () {
          if (isGroup) context.push('/group-info/$chatId');
        },
        child: Row(
          children: [
            UserAvatar(
              name: chatName,
              avatarUrl: chatData?['chatAvatar'] as String?,
              size: 36,
              isOnline: isOnline,
              isGroup: isGroup,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    chatName,
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    isOnline ? 'online' : 'tap for info',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.85),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.call_outlined),
          onPressed: () => context.push('/call/$chatId',
              extra: {'isVideo': false, 'chatName': chatName}),
        ),
        IconButton(
          icon: const Icon(Icons.videocam_outlined),
          onPressed: () => context.push('/call/$chatId',
              extra: {'isVideo': true, 'chatName': chatName}),
        ),
        IconButton(
          icon: const Icon(Icons.more_vert),
          onPressed: () => _showOptions(context),
        ),
      ],
    );
  }

  void _showOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
                color: AppTheme.neutral400.withOpacity(0.4),
                borderRadius: BorderRadius.circular(2)),
          ),
          ListTile(
            leading: const Icon(Icons.search),
            title: const Text('Search in chat'),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.volume_off_outlined),
            title: const Text('Mute notifications'),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.wallpaper_outlined),
            title: const Text('Wallpaper'),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading:
                const Icon(Icons.delete_sweep_outlined, color: AppTheme.statusError),
            title: Text('Clear chat',
                style: TextStyle(color: AppTheme.statusError)),
            onTap: () => Navigator.pop(context),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _MessageList extends StatelessWidget {
  final List<MessageEntity> messages;
  final String currentUserId;
  final ScrollController scrollController;
  final ChatBloc chatBloc;
  final String chatId;

  const _MessageList({
    required this.messages,
    required this.currentUserId,
    required this.scrollController,
    required this.chatBloc,
    required this.chatId,
  });

  @override
  Widget build(BuildContext context) {
    // Group messages by date
    final grouped = <String, List<MessageEntity>>{};
    for (final msg in messages) {
      final key = msg.createdAt.dividerDate;
      grouped.putIfAbsent(key, () => []).add(msg);
    }

    final sections = grouped.entries.toList();

    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: sections.length,
      itemBuilder: (context, sectionIndex) {
        final section = sections[sectionIndex];
        return Column(
          children: [
            _DateDivider(label: section.key),
            ...section.value.map((msg) => MessageBubble(
                  message: msg,
                  isSent: msg.senderId == currentUserId,
                  onLongPress: () => _showMessageOptions(context, msg),
                  onReply: () => chatBloc.add(ChatSetReplyEvent(msg)),
                )),
          ],
        );
      },
    );
  }

  void _showMessageOptions(BuildContext context, MessageEntity message) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
                color: AppTheme.neutral400.withOpacity(0.4),
                borderRadius: BorderRadius.circular(2)),
          ),
          ListTile(
            leading: const Icon(Icons.reply_outlined),
            title: const Text('Reply'),
            onTap: () {
              Navigator.pop(context);
              chatBloc.add(ChatSetReplyEvent(message));
            },
          ),
          if (message.type == MessageType.text)
            ListTile(
              leading: const Icon(Icons.copy_outlined),
              title: const Text('Copy'),
              onTap: () {
                Navigator.pop(context);
                Clipboard.setData(ClipboardData(text: message.content ?? ''));
                context.showSnackBar('Copied to clipboard');
              },
            ),
          ListTile(
            leading: const Icon(Icons.forward_outlined),
            title: const Text('Forward'),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.star_outline),
            title: const Text('Star message'),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: Icon(Icons.delete_outline,
                color: AppTheme.statusError),
            title: Text('Delete',
                style: TextStyle(color: AppTheme.statusError)),
            onTap: () {
              Navigator.pop(context);
              chatBloc.add(ChatDeleteMessageEvent(
                messageId: message.id,
                deleteForEveryone: message.senderId == chatId,
              ));
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _DateDivider extends StatelessWidget {
  final String label;
  const _DateDivider({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFF3F4F6)),
          ),
          child: Text(
            label.toUpperCase(),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppTheme.neutral400,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.6,
                ),
          ),
        ),
      ),
    );
  }
}

class _ReplyPreview extends StatelessWidget {
  final MessageEntity message;
  final VoidCallback onCancel;

  const _ReplyPreview({required this.message, required this.onCancel});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.brandPrimary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Reply',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: AppTheme.brandPrimary,
                          fontWeight: FontWeight.w600,
                        )),
                const SizedBox(height: 2),
                Text(
                  message.content ?? '[media]',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: AppTheme.neutral600),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 20, color: AppTheme.neutral400),
            onPressed: onCancel,
          ),
        ],
      ),
    );
  }
}
