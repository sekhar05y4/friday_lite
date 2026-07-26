import '../interfaces/repositories/i_reminders_repository.dart';
import '../models/reminder.dart';
import '../services/database_service.dart';
import '../utils/logger.dart';

/// Repository managing SQLite persistence for reminders.
class RemindersRepository implements IRemindersRepository {
  RemindersRepository._();

  static final RemindersRepository instance = RemindersRepository._();

  @override
  Future<List<Reminder>> getPendingReminders() async {
    try {
      final db = await DatabaseService.instance.database;
      final rows = await db.query(
        'reminders',
        where: 'is_completed = 0',
        orderBy: 'scheduled_at ASC',
      );
      return rows.map((r) => Reminder.fromMap(r)).toList();
    } catch (e) {
      FridayLogger.error(LogCategory.assistant, 'RemindersRepository getPendingReminders error: $e');
      return [];
    }
  }

  @override
  Future<int> createReminder(String title, DateTime scheduledAt) async {
    try {
      final db = await DatabaseService.instance.database;
      final id = await db.insert('reminders', {
        'title': title,
        'scheduled_at': scheduledAt.millisecondsSinceEpoch,
        'is_completed': 0,
      });
      FridayLogger.log(LogCategory.assistant, 'RemindersRepository: created reminder #$id "$title"');
      return id;
    } catch (e) {
      FridayLogger.error(LogCategory.assistant, 'RemindersRepository createReminder error: $e');
      return -1;
    }
  }

  @override
  Future<bool> markCompleted(int id) async {
    try {
      final db = await DatabaseService.instance.database;
      final count = await db.update(
        'reminders',
        {'is_completed': 1},
        where: 'id = ?',
        whereArgs: [id],
      );
      return count > 0;
    } catch (e) {
      FridayLogger.error(LogCategory.assistant, 'RemindersRepository markCompleted error: $e');
      return false;
    }
  }
}
