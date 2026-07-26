import '../interfaces/repositories/i_calendar_repository.dart';
import '../services/database_service.dart';
import '../utils/logger.dart';

class CalendarRepository implements ICalendarRepository {
  CalendarRepository._();

  static final CalendarRepository instance = CalendarRepository._();

  @override
  Future<List<Map<String, dynamic>>> getUpcomingEvents({int limit = 10}) async {
    try {
      final db = await DatabaseService.instance.database;
      final nowMs = DateTime.now().millisecondsSinceEpoch;
      return await db.query(
        'calendar_events',
        where: 'start_time >= ?',
        whereArgs: [nowMs],
        orderBy: 'start_time ASC',
        limit: limit,
      );
    } catch (e) {
      FridayLogger.error(LogCategory.assistant, 'CalendarRepository getUpcomingEvents error: $e');
      return [];
    }
  }

  @override
  Future<int> addEvent(String title, DateTime startTime, {String? location, String? description}) async {
    try {
      final db = await DatabaseService.instance.database;
      final id = await db.insert('calendar_events', {
        'title': title,
        'start_time': startTime.millisecondsSinceEpoch,
        'location': location,
        'description': description,
      });
      FridayLogger.log(LogCategory.assistant, 'CalendarRepository: added event #$id "$title"');
      return id;
    } catch (e) {
      FridayLogger.error(LogCategory.assistant, 'CalendarRepository addEvent error: $e');
      return -1;
    }
  }

  @override
  Future<bool> deleteEvent(int id) async {
    try {
      final db = await DatabaseService.instance.database;
      final count = await db.delete('calendar_events', where: 'id = ?', whereArgs: [id]);
      return count > 0;
    } catch (e) {
      FridayLogger.error(LogCategory.assistant, 'CalendarRepository deleteEvent error: $e');
      return false;
    }
  }
}
