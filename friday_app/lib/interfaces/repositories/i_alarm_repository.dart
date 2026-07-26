abstract class IAlarmRepository {
  Future<List<Map<String, dynamic>>> getAlarms();
  Future<int> setAlarm(String label, DateTime alarmTime);
  Future<bool> deleteAlarm(int id);
}
