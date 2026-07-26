import '../../models/reminder.dart';

abstract class IRemindersRepository {
  Future<List<Reminder>> getPendingReminders();
  Future<int> createReminder(String title, DateTime scheduledAt);
  Future<bool> markCompleted(int id);
}
