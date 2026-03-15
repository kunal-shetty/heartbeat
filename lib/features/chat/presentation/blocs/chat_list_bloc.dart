import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/chat_entity.dart';
import '../../domain/usecases/get_chats.dart';

// Events
abstract class ChatListEvent extends Equatable {
  @override List<Object?> get props => [];
}
class ChatListLoadEvent extends ChatListEvent {
  final String userId;
  ChatListLoadEvent(this.userId);
  @override List<Object?> get props => [userId];
}
class ChatListRefreshEvent extends ChatListEvent {
  final String userId;
  ChatListRefreshEvent(this.userId);
  @override List<Object?> get props => [userId];
}
class ChatListUpdateEvent extends ChatListEvent {
  final List<ChatEntity> chats;
  ChatListUpdateEvent(this.chats);
  @override List<Object?> get props => [chats];
}

// States
abstract class ChatListState extends Equatable {
  @override List<Object?> get props => [];
}
class ChatListInitialState extends ChatListState {}
class ChatListLoadingState extends ChatListState {}
class ChatListLoadedState extends ChatListState {
  final List<ChatEntity> chats;
  final List<ChatEntity> pinnedChats;
  final List<ChatEntity> regularChats;

  ChatListLoadedState(List<ChatEntity> allChats)
      : chats = allChats,
        pinnedChats = allChats.where((c) => c.isPinned).toList(),
        regularChats = allChats.where((c) => !c.isPinned).toList();

  @override List<Object?> get props => [chats];
}
class ChatListErrorState extends ChatListState {
  final String message;
  ChatListErrorState(this.message);
  @override List<Object?> get props => [message];
}

// BLoC
class ChatListBloc extends Bloc<ChatListEvent, ChatListState> {
  final GetChats getChats;
  StreamSubscription? _subscription;

  ChatListBloc({required this.getChats}) : super(ChatListInitialState()) {
    on<ChatListLoadEvent>(_onLoad);
    on<ChatListRefreshEvent>(_onRefresh);
    on<ChatListUpdateEvent>(_onUpdate);
  }

  Future<void> _onLoad(ChatListLoadEvent event, Emitter<ChatListState> emit) async {
    emit(ChatListLoadingState());
    try {
      final chats = await getChats(event.userId);
      emit(ChatListLoadedState(chats));

      // Watch for realtime updates
      _subscription?.cancel();
      _subscription = getChats.watch(event.userId).listen((chats) {
        add(ChatListUpdateEvent(chats));
      });
    } catch (e) {
      emit(ChatListErrorState(e.toString()));
    }
  }

  Future<void> _onRefresh(ChatListRefreshEvent event, Emitter<ChatListState> emit) async {
    try {
      final chats = await getChats(event.userId);
      emit(ChatListLoadedState(chats));
    } catch (_) {}
  }

  void _onUpdate(ChatListUpdateEvent event, Emitter<ChatListState> emit) {
    emit(ChatListLoadedState(event.chats));
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
