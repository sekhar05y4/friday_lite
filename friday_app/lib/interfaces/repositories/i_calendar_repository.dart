abstract class ICalendarRepository {
  Future<List<Map<String, dynamic>>> getUpcomingEvents({int limit = 10});
  Future<int> addEvent(String title, DateTime startTime, {String? location, String? description});
  Future<bool> deleteEvent(int id);
}
