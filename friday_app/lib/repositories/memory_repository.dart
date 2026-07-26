import '../interfaces/repositories/i_memory_repository.dart';
import '../services/database_service.dart';
import '../utils/logger.dart';

/// Repository managing FRIDAY's Long-Term Memory System.
///
/// Handles 5 memory categories:
///   1. conversation
///   2. preference
///   3. knowledge
///   4. relationship
///   5. task
///
/// Features memory ranking (relevance score), expiration filtering, keyword search,
/// and editing/deletion without direct SQLite calls outside this repository.
class MemoryRepository implements IMemoryRepository {
  MemoryRepository._();

  static final MemoryRepository instance = MemoryRepository._();

  @override
  Future<Map<String, dynamic>> getMemorySummary() async {
    try {
      final db = await DatabaseService.instance.database;

      final chatCount = await _tableCount(db, 'chat_messages');
      final notesCount = await _tableCount(db, 'notes');
      final remindersCount = await _tableCount(db, 'reminders');
      final contactsCount = await _tableCount(db, 'contacts');
      final memoryCount = await _tableCount(db, 'long_term_memory');

      return {
        'chat_messages_count': chatCount,
        'notes_count': notesCount,
        'reminders_count': remindersCount,
        'contacts_count': contactsCount,
        'long_term_memories_count': memoryCount,
      };
    } catch (e) {
      FridayLogger.error(LogCategory.assistant, 'MemoryRepository getMemorySummary error: $e');
      return {
        'chat_messages_count': 0,
        'notes_count': 0,
        'reminders_count': 0,
        'contacts_count': 0,
        'long_term_memories_count': 0,
      };
    }
  }

  @override
  Future<int> saveMemory(
    String memoryType,
    String key,
    String value, {
    int ranking = 1,
    DateTime? expiresAt,
  }) async {
    try {
      final db = await DatabaseService.instance.database;
      final nowMs = DateTime.now().millisecondsSinceEpoch;
      final expiresMs = expiresAt?.millisecondsSinceEpoch;

      final id = await db.insert('long_term_memory', {
        'memory_type': memoryType,
        'key': key,
        'value': value,
        'ranking': ranking,
        'created_at': nowMs,
        'expires_at': expiresMs,
      });

      FridayLogger.log(
        LogCategory.assistant,
        'MemoryRepository: saved $memoryType memory #$id "$key": "$value" (rank: $ranking)',
      );
      return id;
    } catch (e) {
      FridayLogger.error(LogCategory.assistant, 'MemoryRepository saveMemory error: $e');
      return -1;
    }
  }

  @override
  Future<List<Map<String, dynamic>>> searchMemory(String query) async {
    try {
      final db = await DatabaseService.instance.database;
      final nowMs = DateTime.now().millisecondsSinceEpoch;
      final lower = query.toLowerCase().trim();

      return await db.query(
        'long_term_memory',
        where: '(expires_at IS NULL OR expires_at > ?) AND (key LIKE ? OR value LIKE ? OR memory_type LIKE ?)',
        whereArgs: [nowMs, '%$lower%', '%$lower%', '%$lower%'],
        orderBy: 'ranking DESC, created_at DESC',
      );
    } catch (e) {
      FridayLogger.error(LogCategory.assistant, 'MemoryRepository searchMemory error: $e');
      return [];
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getMemoriesByType(String memoryType) async {
    try {
      final db = await DatabaseService.instance.database;
      final nowMs = DateTime.now().millisecondsSinceEpoch;

      return await db.query(
        'long_term_memory',
        where: 'memory_type = ? AND (expires_at IS NULL OR expires_at > ?)',
        whereArgs: [memoryType, nowMs],
        orderBy: 'ranking DESC, created_at DESC',
      );
    } catch (e) {
      FridayLogger.error(LogCategory.assistant, 'MemoryRepository getMemoriesByType error: $e');
      return [];
    }
  }

  @override
  Future<bool> editMemory(String key, String newValue) async {
    try {
      final db = await DatabaseService.instance.database;
      final count = await db.update(
        'long_term_memory',
        {'value': newValue},
        where: 'key LIKE ?',
        whereArgs: ['%$key%'],
      );
      FridayLogger.log(LogCategory.assistant, 'MemoryRepository: updated memory "$key"');
      return count > 0;
    } catch (e) {
      FridayLogger.error(LogCategory.assistant, 'MemoryRepository editMemory error: $e');
      return false;
    }
  }

  @override
  Future<bool> forgetMemory(String key) async {
    try {
      final db = await DatabaseService.instance.database;
      final count = await db.delete(
        'long_term_memory',
        where: 'key LIKE ? OR value LIKE ?',
        whereArgs: ['%$key%', '%$key%'],
      );
      FridayLogger.log(LogCategory.assistant, 'MemoryRepository: deleted memory matching "$key"');
      return count > 0;
    } catch (e) {
      FridayLogger.error(LogCategory.assistant, 'MemoryRepository forgetMemory error: $e');
      return false;
    }
  }

  Future<int> _tableCount(var db, String table) async {
    try {
      final res = await db.rawQuery('SELECT COUNT(*) as count FROM $table');
      return (res.first['count'] as int?) ?? 0;
    } catch (_) {
      return 0;
    }
  }
}
