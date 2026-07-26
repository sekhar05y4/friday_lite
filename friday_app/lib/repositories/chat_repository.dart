import '../interfaces/repositories/i_chat_repository.dart';
import '../models/chat_message.dart';
import '../services/database_service.dart';
import '../utils/logger.dart';

/// Repository for persisting and retrieving conversation history.
///
/// Neither AI providers nor UI components access SQLite directly;
/// all chat message persistence flows through [ChatRepository].
class ChatRepository implements IChatRepository {
  ChatRepository._();

  static final ChatRepository instance = ChatRepository._();

  /// Retrieve the most recent [limit] chat messages ordered by timestamp ascending.
  @override
  Future<List<ChatMessage>> getRecentMessages({int limit = 50}) async {
    try {
      final db = await DatabaseService.instance.database;
      final List<Map<String, dynamic>> rows = await db.query(
        'chat_messages',
        orderBy: 'timestamp ASC',
        limit: limit,
      );

      return rows.map((r) => ChatMessage.fromMap(r)).toList();
    } catch (e) {
      FridayLogger.error(LogCategory.assistant, 'ChatRepository: failed to fetch messages: $e');
      return [];
    }
  }

  /// Insert a new chat message into history.
  @override
  Future<void> saveMessage(ChatMessage message) async {
    try {
      final db = await DatabaseService.instance.database;
      await db.insert('chat_messages', message.toMap());
      FridayLogger.log(
        LogCategory.assistant,
        'ChatRepository: saved message [${message.role}] "${_truncate(message.content)}"',
      );
    } catch (e) {
      FridayLogger.error(LogCategory.assistant, 'ChatRepository: failed to save message: $e');
    }
  }

  /// Clear all conversation history.
  @override
  Future<void> clearHistory() async {
    try {
      final db = await DatabaseService.instance.database;
      await db.delete('chat_messages');
      FridayLogger.log(LogCategory.assistant, 'ChatRepository: history cleared');
    } catch (e) {
      FridayLogger.error(LogCategory.assistant, 'ChatRepository: failed to clear history: $e');
    }
  }

  String _truncate(String text) =>
      text.length > 40 ? '${text.substring(0, 40)}…' : text;
}
