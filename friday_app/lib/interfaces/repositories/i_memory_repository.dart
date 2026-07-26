abstract class IMemoryRepository {
  Future<Map<String, dynamic>> getMemorySummary();
  Future<int> saveMemory(
    String memoryType,
    String key,
    String value, {
    int ranking = 1,
    DateTime? expiresAt,
  });
  Future<List<Map<String, dynamic>>> searchMemory(String query);
  Future<List<Map<String, dynamic>>> getMemoriesByType(String memoryType);
  Future<bool> editMemory(String key, String newValue);
  Future<bool> forgetMemory(String key);
}
