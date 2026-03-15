import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/chat_entity.dart';
import '../models/message_model.dart';
import '../models/chat_model.dart';

abstract class ChatLocalDataSource {
  Future<List<MessageEntity>> getCachedMessages(String chatId);
  Future<void> cacheMessages(List<MessageEntity> messages);
  Future<void> cacheMessage(MessageEntity message);
  Future<void> updateMessageStatus(String messageId, MessageStatus status);
  Future<List<MessageEntity>> getPendingMessages();
  Future<void> deleteMessage(String messageId);
  Future<List<ChatEntity>> getCachedChats();
  Future<void> cacheChats(List<ChatEntity> chats);
}

class ChatLocalDataSourceImpl implements ChatLocalDataSource {
  // In-memory store — keyed by chatId for messages, flat list for chats
  final Map<String, List<MessageModel>> _messagesCache = {};
  final List<ChatModel> _chatsCache = [];

  static const _chatsKey = 'cached_chats';
  static String _messagesKey(String chatId) => 'cached_messages_$chatId';

  // ── Messages ─────────────────────────────────────────────────────────────

  @override
  Future<List<MessageEntity>> getCachedMessages(String chatId) async {
    // Return in-memory first
    if (_messagesCache.containsKey(chatId)) {
      return _messagesCache[chatId]!
          .map((m) => m.toEntity())
          .toList();
    }
    // Fall back to SharedPreferences
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_messagesKey(chatId));
      if (raw == null) return [];
      final list = jsonDecode(raw) as List;
      final models =
          list.map((e) => MessageModel.fromJson(e as Map<String, dynamic>)).toList();
      _messagesCache[chatId] = models;
      return models.map((m) => m.toEntity()).toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<void> cacheMessages(List<MessageEntity> messages) async {
    if (messages.isEmpty) return;
    final chatId = messages.first.chatId;
    final models = messages.map(MessageModel.fromEntity).toList();

    // Merge with existing — deduplicate by id
    final existing = Map<String, MessageModel>.fromEntries(
      (_messagesCache[chatId] ?? []).map((m) => MapEntry(m.id, m)),
    );
    for (final m in models) {
      existing[m.id] = m;
    }
    final merged = existing.values.toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

    _messagesCache[chatId] = merged;
    await _persistMessages(chatId, merged);
  }

  @override
  Future<void> cacheMessage(MessageEntity message) async {
    final chatId = message.chatId;
    final model = MessageModel.fromEntity(message);
    final list = _messagesCache[chatId] ?? [];

    final idx = list.indexWhere((m) => m.id == model.id);
    if (idx >= 0) {
      list[idx] = model;
    } else {
      list.add(model);
    }
    _messagesCache[chatId] = list;
    await _persistMessages(chatId, list);
  }

  @override
  Future<void> updateMessageStatus(String messageId, MessageStatus status) async {
    for (final entry in _messagesCache.entries) {
      final idx = entry.value.indexWhere((m) => m.id == messageId);
      if (idx >= 0) {
        final old = entry.value[idx];
        final updated = MessageModel(
          id: old.id,
          chatId: old.chatId,
          senderId: old.senderId,
          content: old.content,
          type: old.type,
          mediaUrl: old.mediaUrl,
          replyToId: old.replyToId,
          isDeleted: old.isDeleted,
          status: status.name,
          createdAt: old.createdAt,
        );
        entry.value[idx] = updated;
        await _persistMessages(entry.key, entry.value);
        return;
      }
    }
  }

  @override
  Future<List<MessageEntity>> getPendingMessages() async {
    final pending = <MessageEntity>[];
    for (final list in _messagesCache.values) {
      pending.addAll(
        list.where((m) => m.status == 'pending').map((m) => m.toEntity()),
      );
    }
    return pending;
  }

  @override
  Future<void> deleteMessage(String messageId) async {
    for (final entry in _messagesCache.entries) {
      final before = entry.value.length;
      entry.value.removeWhere((m) => m.id == messageId);
      if (entry.value.length != before) {
        await _persistMessages(entry.key, entry.value);
        return;
      }
    }
  }

  // ── Chats ─────────────────────────────────────────────────────────────────

  @override
  Future<List<ChatEntity>> getCachedChats() async {
    if (_chatsCache.isNotEmpty) {
      return _chatsCache.map((c) => c.toEntity()).toList();
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_chatsKey);
      if (raw == null) return [];
      final list = jsonDecode(raw) as List;
      final models =
          list.map((e) => ChatModel.fromJson(e as Map<String, dynamic>)).toList();
      _chatsCache
        ..clear()
        ..addAll(models);
      return models.map((c) => c.toEntity()).toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<void> cacheChats(List<ChatEntity> chats) async {
    final models = chats.map(ChatModel.fromEntity).toList();
    _chatsCache
      ..clear()
      ..addAll(models);
    await _persistChats(models);
  }

  // ── Persistence helpers ───────────────────────────────────────────────────

  Future<void> _persistMessages(String chatId, List<MessageModel> models) async {
    try {
      // Only keep last 100 messages per chat to avoid bloating storage
      final toSave = models.length > 100
          ? models.sublist(models.length - 100)
          : models;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _messagesKey(chatId),
        jsonEncode(toSave.map((m) => m.toJson()).toList()),
      );
    } catch (_) {}
  }

  Future<void> _persistChats(List<ChatModel> models) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _chatsKey,
        jsonEncode(models.map((c) => c.toJson()).toList()),
      );
    } catch (_) {}
  }
}
