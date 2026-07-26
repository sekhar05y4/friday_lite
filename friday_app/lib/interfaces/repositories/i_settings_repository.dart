abstract class ISettingsRepository {
  Future<String> getString(String key, String defaultValue);
  Future<void> setString(String key, String value);
  Future<String> getBackendUrl();
  Future<void> setBackendUrl(String url);
  Future<String> getAiProvider();
  Future<void> setAiProvider(String providerId);
}
