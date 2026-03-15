import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/chat_entity.dart';
import '../../domain/repositories/chat_repository.dart';
import '../../domain/usecases/get_chats.dart';
import '../../domain/usecases/get_messages.dart';
import '../../domain/usecases/send_message.dart';
import '../../domain/usecases/delete_message.dart';

// Events
abstract class ChatEvent extends Equatable {
  @override List<Object?> get props => [];
}
class ChatLoadEvent extends ChatEvent {
  final String chatId;
  final String currentUserId;
  ChatLoadEvent({required this.chatId, required this.currentUserId});
  @override List<Object?> get props => [chatId, currentUserId];
}
class ChatSendMessageEvent extends ChatEvent {
  final String chatId, senderId;
  final String? content;
  final MessageType type;
  final String? mediaUrl, replyToId;
  ChatSendMessageEvent({
    required this.chatId, required this.senderId,
    this.content, required this.type,
    this.mediaUrl, this.replyToId,
  });
  @override List<Object?> get props => [chatId, content, type];
}
class ChatNewMessageEvent extends ChatEvent {
  final MessageEntity message;
  ChatNewMessageEvent(this.message);
  @override List<Object?> get props => [message];
}
class ChatDeleteMessageEvent extends ChatEvent {
  final String messageId;
  final bool deleteForEveryone;
  ChatDeleteMessageEvent({required this.messageId, this.deleteForEveryone = false});
  @override List<Object?> get props => [messageId, deleteForEveryone];
}
class ChatLoadMoreEvent extends ChatEvent {
  final String chatId;
  ChatLoadMoreEvent(this.chatId);
}
class ChatTypingEvent extends ChatEvent {
  final String chatId, userId;
  final bool isTyping;
  ChatTypingEvent({required this.chatId, required this.userId, required this.isTyping});
}
class ChatTypingUpdateEvent extends ChatEvent {
  final List<String> typingUserIds;
  ChatTypingUpdateEvent(this.typingUserIds);
}
class ChatSetReplyEvent extends ChatEvent {
  final MessageEntity? message;
  ChatSetReplyEvent(this.message);
}

// States
abstract class ChatState extends Equatable {
  @override List<Object?> get props => [];
}
class ChatInitialState extends ChatState {}
class ChatLoadingState extends ChatState {}
class ChatLoadedState extends ChatState {
  final List<MessageEntity> messages;
  final bool hasMore;
  final bool isSending;
  final List<String> typingUserIds;
  final MessageEntity? replyToMessage;

  ChatLoadedState({
    required this.messages,
    this.hasMore = true,
    this.isSending = false,
    this.typingUserIds = const [],
    this.replyToMessage,
  });

  ChatLoadedState copyWith({
    List<MessageEntity>? messages,
    bool? hasMore,
    bool? isSending,
    List<String>? typingUserIds,
    MessageEntity? replyToMessage,
    bool clearReply = false,
  }) {
    return ChatLoadedState(
      messages: messages ?? this.messages,
      hasMore: hasMore ?? this.hasMore,
      isSending: isSending ?? this.isSending,
      typingUserIds: typingUserIds ?? this.typingUserIds,
      replyToMessage: clearReply ? null : replyToMessage ?? this.replyToMessage,
    );
  }

  @override List<Object?> get props => [messages, hasMore, isSending, typingUserIds, replyToMessage];
}
class ChatErrorState extends ChatState {
  final String message;
  ChatErrorState(this.message);
  @override List<Object?> get props => [message];
}

// BLoC
class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final SendMessage sendMessage;
  final GetMessages getMessages;
  final DeleteMessage deleteMessage;
  final ChatRepository chatRepository;

  StreamSubscription? _messageSubscription;
  StreamSubscription? _typingSubscription;

  ChatBloc({
    required this.sendMessage,
    required this.getMessages,
    required this.deleteMessage,
    required this.chatRepository,
  }) : super(ChatInitialState()) {
    on<ChatLoadEvent>(_onLoad);
    on<ChatSendMessageEvent>(_onSend);
    on<ChatNewMessageEvent>(_onNewMessage);
    on<ChatDeleteMessageEvent>(_onDelete);
    on<ChatLoadMoreEvent>(_onLoadMore);
    on<ChatTypingEvent>(_onTyping);
    on<ChatTypingUpdateEvent>(_onTypingUpdate);
    on<ChatSetReplyEvent>(_onSetReply);
  }

  Future<void> _onLoad(ChatLoadEvent event, Emitter<ChatState> emit) async {
    emit(ChatLoadingState());
    try {
      final messages = await getMessages(chatId: event.chatId);
      emit(ChatLoadedState(messages: messages));

      // Mark as read
      await chatRepository.markMessagesRead(
          chatId: event.chatId, userId: event.currentUserId);

      // Subscribe to new messages
      _messageSubscription?.cancel();
      _messageSubscription = getMessages
          .watch(event.chatId)
          .listen((msg) => add(ChatNewMessageEvent(msg)));

      // Subscribe to typing
      _typingSubscription?.cancel();
      _typingSubscription = chatRepository
          .watchTypingUsers(event.chatId)
          .listen((ids) => add(ChatTypingUpdateEvent(ids)));
    } catch (e) {
      emit(ChatErrorState(e.toString()));
    }
  }

  Future<void> _onSend(ChatSendMessageEvent event, Emitter<ChatState> emit) async {
    final current = state;
    if (current is! ChatLoadedState) return;

    // Optimistic UI
    final optimistic = MessageEntity(
      id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
      chatId: event.chatId,
      senderId: event.senderId,
      content: event.content,
      type: event.type,
      mediaUrl: event.mediaUrl,
      replyToId: event.replyToId,
      status: MessageStatus.pending,
      createdAt: DateTime.now(),
    );

    emit(current.copyWith(
      messages: [...current.messages, optimistic],
      isSending: true,
      clearReply: true,
    ));

    try {
      final sent = await sendMessage(
        chatId: event.chatId,
        senderId: event.senderId,
        content: event.content,
        type: event.type,
        mediaUrl: event.mediaUrl,
        replyToId: event.replyToId,
      );

      final updatedMessages = (state as ChatLoadedState)
          .messages
          .map((m) => m.id == optimistic.id ? sent : m)
          .toList();

      emit((state as ChatLoadedState).copyWith(
        messages: updatedMessages,
        isSending: false,
      ));
    } catch (e) {
      // Mark as failed
      final failedMessages = (state as ChatLoadedState)
          .messages
          .map((m) => m.id == optimistic.id
              ? m.copyWith(status: MessageStatus.failed)
              : m)
          .toList();
      emit((state as ChatLoadedState).copyWith(
        messages: failedMessages,
        isSending: false,
      ));
    }
  }

  void _onNewMessage(ChatNewMessageEvent event, Emitter<ChatState> emit) {
    final current = state;
    if (current is! ChatLoadedState) return;
    // Avoid duplicates
    final exists = current.messages.any((m) => m.id == event.message.id);
    if (!exists) {
      emit(current.copyWith(
        messages: [...current.messages, event.message],
      ));
    }
  }

  Future<void> _onDelete(ChatDeleteMessageEvent event, Emitter<ChatState> emit) async {
    await deleteMessage(
        messageId: event.messageId,
        deleteForEveryone: event.deleteForEveryone);
    final current = state;
    if (current is ChatLoadedState) {
      emit(current.copyWith(
        messages: current.messages.where((m) => m.id != event.messageId).toList(),
      ));
    }
  }

  Future<void> _onLoadMore(ChatLoadMoreEvent event, Emitter<ChatState> emit) async {
    final current = state;
    if (current is! ChatLoadedState || !current.hasMore) return;
    try {
      final oldest = current.messages.isNotEmpty
          ? current.messages.first.createdAt.toIso8601String()
          : null;
      final older = await getMessages(chatId: event.chatId, before: oldest);
      if (older.isEmpty) {
        emit(current.copyWith(hasMore: false));
      } else {
        emit(current.copyWith(messages: [...older, ...current.messages]));
      }
    } catch (_) {}
  }

  Future<void> _onTyping(ChatTypingEvent event, Emitter<ChatState> emit) async {
    await chatRepository.sendTypingIndicator(
        chatId: event.chatId, userId: event.userId, isTyping: event.isTyping);
  }

  void _onTypingUpdate(ChatTypingUpdateEvent event, Emitter<ChatState> emit) {
    final current = state;
    if (current is ChatLoadedState) {
      emit(current.copyWith(typingUserIds: event.typingUserIds));
    }
  }

  void _onSetReply(ChatSetReplyEvent event, Emitter<ChatState> emit) {
    final current = state;
    if (current is ChatLoadedState) {
      if (event.message == null) {
        emit(current.copyWith(clearReply: true));
      } else {
        emit(current.copyWith(replyToMessage: event.message));
      }
    }
  }

  @override
  Future<void> close() {
    _messageSubscription?.cancel();
    _typingSubscription?.cancel();
    return super.close();
  }
}
