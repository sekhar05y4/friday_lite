import 'package:sqflite/sqflite.dart';

import '../interfaces/repositories/i_settings_repository.dart';
import '../config/api_config.dart';
import '../services/database_service.dart';
import '../utils/logger.dart';

/// Repository for persisting key-value settings.
///
/// Encapsulates storage for active backend URL, selected AI provider, voice rate, pitch, etc.
class SettingsRepository implements ISettingsRepository {
  SettingsRepository._();

  static final SettingsRepository instance = SettingsRepository._();

  /// Retrieve a setting value by key, returning [defaultValue] if not found.
  @override
  Future<String> getString(String key, String defaultValue) async {
    try {
      final db = await DatabaseService.instance.database;
      final rows = await db.query(
        'settings',
        columns: ['value'],
        where: 'key = ?',
        whereArgs: [key],
      );

      if (rows.isNotEmpty) {
        return rows.first['value'] as String;
      }
    } catch (e) {
      FridayLogger.error(LogCategory.assistant, 'SettingsRepository: error reading $key: $e');
    }
    return defaultValue;
  }

  /// Set a setting key-value pair.
  @override
  Future<void> setString(String key, String value) async {
    try {
      final db = await DatabaseService.instance.database;
      await db.insert(
        'settings',
        {'key': key, 'value': value},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      FridayLogger.log(LogCategory.assistant, 'SettingsRepository: set $key = $value');
    } catch (e) {
      FridayLogger.error(LogCategory.assistant, 'SettingsRepository: error writing $key: $e');
    }
  }

  /// Helper to get the active backend URL.
  @override
  Future<String> getBackendUrl() =>
      getString('backend_url', ApiConfig.defaultBaseUrl);

  /// Helper to set the active backend URL.
  @override
  Future<void> setBackendUrl(String url) => setString('backend_url', url);

  /// Helper to get the active AI provider ID.
  @override
  Future<String> getAiProvider() => getString('ai_provider', 'gemini');

  /// Helper to set the active AI provider ID.
  @override
  Future<void> setAiProvider(String providerId) =>
      setString('ai_provider', providerId);
}
