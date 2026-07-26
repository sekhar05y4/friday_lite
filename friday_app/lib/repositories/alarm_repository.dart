import '../interfaces/repositories/i_alarm_repository.dart';
import '../services/database_service.dart';
import '../utils/logger.dart';

class AlarmRepository implements IAlarmRepository {
  AlarmRepository._();

  static final AlarmRepository instance = AlarmRepository._();

  @override
  Future<List<Map<String, dynamic>>> getAlarms() async {
    try {
      final db = await DatabaseService.instance.database;
      return await db.query('alarms', orderBy: 'alarm_time ASC');
    } catch (e) {
      FridayLogger.error(LogCategory.assistant, 'AlarmRepository getAlarms error: $e');
      return [];
    }
  }

  @override
  Future<int> setAlarm(String label, DateTime alarmTime) async {
    try {
      final db = await DatabaseService.instance.database;
      final id = await db.insert('alarms', {
        'label': label,
        'alarm_time': alarmTime.millisecondsSinceEpoch,
        'is_enabled': 1,
      });
      FridayLogger.log(LogCategory.assistant, 'AlarmRepository: set alarm #$id "$label"');
      return id;
    } catch (e) {
      FridayLogger.error(LogCategory.assistant, 'AlarmRepository setAlarm error: $e');
      return -1;
    }
  }

  @override
  Future<bool> deleteAlarm(int id) async {
    try {
      final db = await DatabaseService.instance.database;
      final count = await db.delete('alarms', where: 'id = ?', whereArgs: [id]);
      return count > 0;
    } catch (e) {
      FridayLogger.error(LogCategory.assistant, 'AlarmRepository deleteAlarm error: $e');
      return false;
    }
  }
}
