class SupabaseConstants {
  // Replace with your actual Supabase project URL and anon key
  static const String supabaseUrl = '';
  static const String supabaseAnonKey = '';

  // Table names
  static const String usersTable = 'users';
  static const String chatsTable = 'chats';
  static const String chatParticipantsTable = 'chat_participants';
  static const String messagesTable = 'messages';
  static const String messageStatusTable = 'message_status';

  // Storage buckets
  static const String avatarsBucket = 'avatars';
  static const String chatMediaBucket = 'chat-media';
  static const String groupIconsBucket = 'group-icons';

  // Realtime channels
  static String chatChannel(String chatId) => 'chat:$chatId';
  static String presenceChannel(String chatId) => 'presence:$chatId';
}

class AppConstants {
  static const int maxImageSizeMb = 20;
  static const int maxVideoSizeMb = 100;
  static const int maxDocumentSizeMb = 50;
  static const int maxPinnedChats = 3;
  static const int messagePaginationLimit = 30;
  static const int chatListPaginationLimit = 20;
  static const Duration signedUrlExpiry = Duration(hours: 1);
  static const Duration typingIndicatorTimeout = Duration(seconds: 3);
}
