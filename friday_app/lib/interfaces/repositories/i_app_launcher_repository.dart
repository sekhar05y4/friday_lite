abstract class IAppLauncherRepository {
  Future<void> seedDefaultApps();
  Future<List<Map<String, dynamic>>> searchApps(String query);
  Future<List<Map<String, dynamic>>> getAppsByCategory(String category);
  Future<List<Map<String, dynamic>>> getMostUsedApps({int limit = 5});
  Future<List<Map<String, dynamic>>> getRecentApps({int limit = 5});
  Future<void> recordAppLaunch(String packageName);
}
