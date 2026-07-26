import '../../models/chat_message.dart';

abstract class IChatRepository {
  Future<List<ChatMessage>> getRecentMessages({int limit = 50});
  Future<void> saveMessage(ChatMessage message);
  Future<void> clearHistory();
}
