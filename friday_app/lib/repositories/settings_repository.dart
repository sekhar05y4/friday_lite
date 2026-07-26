import 'package:shared_preferences/shared_preferences.dart';

import '../config/api_config.dart';
import '../interfaces/repositories/i_settings_repository.dart';
import '../services/api_service.dart';
import '../utils/logger.dart';

/// Repository for persisting key-value settings via SharedPreferences & in-memory cache.
class SettingsRepository implements ISettingsRepository {
  SettingsRepository._() {
    _initMemoryCache();
  }

  static final SettingsRepository instance = SettingsRepository._();

  String? _cachedBackendUrl;
  String? _cachedAiProvider;

  Future<void> _initMemoryCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _cachedBackendUrl = prefs.getString('backend_url') ?? ApiConfig.defaultBaseUrl;
      _cachedAiProvider = prefs.getString('ai_provider') ?? 'gemini';
      ApiService.instance.setBaseUrl(_cachedBackendUrl!);
      FridayLogger.log(LogCategory.assistant, 'SettingsRepository: cache loaded backend_url=$_cachedBackendUrl');
    } catch (e) {
      FridayLogger.error(LogCategory.assistant, 'SettingsRepository init error: $e');
    }
  }

  @override
  Future<String> getString(String key, String defaultValue) async {
    if (key == 'backend_url' && _cachedBackendUrl != null) return _cachedBackendUrl!;
    if (key == 'ai_provider' && _cachedAiProvider != null) return _cachedAiProvider!;

    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(key) ?? defaultValue;
    } catch (e) {
      FridayLogger.error(LogCategory.assistant, 'SettingsRepository: error reading $key: $e');
    }
    return defaultValue;
  }

  @override
  Future<void> setString(String key, String value) async {
    if (key == 'backend_url') {
      _cachedBackendUrl = value;
      ApiService.instance.setBaseUrl(value);
    }
    if (key == 'ai_provider') {
      _cachedAiProvider = value;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, value);
      FridayLogger.log(LogCategory.assistant, 'SettingsRepository: saved $key = $value');
    } catch (e) {
      FridayLogger.error(LogCategory.assistant, 'SettingsRepository: error writing $key: $e');
    }
  }

  @override
  Future<String> getBackendUrl() async {
    if (_cachedBackendUrl != null) return _cachedBackendUrl!;
    return getString('backend_url', ApiConfig.defaultBaseUrl);
  }

  @override
  Future<void> setBackendUrl(String url) async {
    _cachedBackendUrl = url;
    ApiService.instance.setBaseUrl(url);
    await setString('backend_url', url);
  }

  @override
  Future<String> getAiProvider() async {
    if (_cachedAiProvider != null) return _cachedAiProvider!;
    return getString('ai_provider', 'gemini');
  }

  @override
  Future<void> setAiProvider(String providerId) async {
    _cachedAiProvider = providerId;
    await setString('ai_provider', providerId);
  }
}
