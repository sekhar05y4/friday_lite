import 'package:sqflite/sqflite.dart';

import '../interfaces/repositories/i_app_launcher_repository.dart';
import '../services/database_service.dart';
import '../utils/logger.dart';

/// Repository managing installed apps database, fuzzy matching, and usage stats.
class AppLauncherRepository implements IAppLauncherRepository {
  AppLauncherRepository._();

  static final AppLauncherRepository instance = AppLauncherRepository._();

  static const List<Map<String, String>> _defaultAppSeed = [
    {'package_name': 'com.android.camera', 'app_name': 'Camera', 'category': 'camera'},
    {'package_name': 'com.android.chrome', 'app_name': 'Chrome', 'category': 'browser'},
    {'package_name': 'com.whatsapp', 'app_name': 'WhatsApp', 'category': 'social'},
    {'package_name': 'com.instagram.android', 'app_name': 'Instagram', 'category': 'social'},
    {'package_name': 'com.spotify.music', 'app_name': 'Spotify', 'category': 'media'},
    {'package_name': 'com.google.android.youtube', 'app_name': 'YouTube', 'category': 'media'},
    {'package_name': 'dev.flutter.app', 'app_name': 'Flutter Project', 'category': 'developer'},
    {'package_name': 'com.google.android.calculator', 'app_name': 'Calculator', 'category': 'tools'},
    {'package_name': 'com.android.settings', 'app_name': 'Settings', 'category': 'system'},
    {'package_name': 'com.google.android.apps.photos', 'app_name': 'Photos', 'category': 'media'},
    {'package_name': 'com.google.android.apps.maps', 'app_name': 'Maps', 'category': 'tools'},
    {'package_name': 'com.google.android.gm', 'app_name': 'Gmail', 'category': 'productivity'},
  ];

  @override
  Future<void> seedDefaultApps() async {
    try {
      final db = await DatabaseService.instance.database;
      final count = Sqflite.firstIntValue(
            await db.rawQuery('SELECT COUNT(*) FROM installed_apps'),
          ) ??
          0;

      if (count == 0) {
        for (final app in _defaultAppSeed) {
          await db.insert('installed_apps', {
            'package_name': app['package_name'],
            'app_name': app['app_name'],
            'category': app['category'],
            'launch_count': 0,
            'last_launched': null,
          });
        }
        FridayLogger.log(
          LogCategory.assistant,
          'AppLauncherRepository: seeded ${_defaultAppSeed.length} default apps',
        );
      }
    } catch (e) {
      FridayLogger.error(LogCategory.assistant, 'AppLauncherRepository seed error: $e');
    }
  }

  @override
  Future<List<Map<String, dynamic>>> searchApps(String query) async {
    await seedDefaultApps();
    try {
      final db = await DatabaseService.instance.database;
      final lower = query.toLowerCase().trim();

      // Alias fuzzy mappings
      final String expandedQuery;
      if (lower.contains('insta')) {
        expandedQuery = 'instagram';
      } else if (lower.contains('tube')) {
        expandedQuery = 'youtube';
      } else if (lower.contains('music') || lower.contains('song')) {
        expandedQuery = 'spotify';
      } else if (lower.contains('photo') || lower.contains('gallery')) {
        expandedQuery = 'photos';
      } else if (lower.contains('web') || lower.contains('browser')) {
        expandedQuery = 'chrome';
      } else {
        expandedQuery = lower;
      }

      return await db.query(
        'installed_apps',
        where: 'app_name LIKE ? OR category LIKE ? OR package_name LIKE ?',
        whereArgs: ['%$expandedQuery%', '%$expandedQuery%', '%$expandedQuery%'],
        orderBy: 'launch_count DESC',
      );
    } catch (e) {
      FridayLogger.error(LogCategory.assistant, 'AppLauncherRepository search error: $e');
      return [];
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getAppsByCategory(String category) async {
    await seedDefaultApps();
    try {
      final db = await DatabaseService.instance.database;
      return await db.query(
        'installed_apps',
        where: 'category LIKE ?',
        whereArgs: ['%$category%'],
        orderBy: 'launch_count DESC',
      );
    } catch (e) {
      FridayLogger.error(LogCategory.assistant, 'AppLauncherRepository getAppsByCategory error: $e');
      return [];
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getMostUsedApps({int limit = 5}) async {
    await seedDefaultApps();
    try {
      final db = await DatabaseService.instance.database;
      return await db.query(
        'installed_apps',
        orderBy: 'launch_count DESC',
        limit: limit,
      );
    } catch (e) {
      FridayLogger.error(LogCategory.assistant, 'AppLauncherRepository getMostUsedApps error: $e');
      return [];
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getRecentApps({int limit = 5}) async {
    await seedDefaultApps();
    try {
      final db = await DatabaseService.instance.database;
      return await db.query(
        'installed_apps',
        where: 'last_launched IS NOT NULL',
        orderBy: 'last_launched DESC',
        limit: limit,
      );
    } catch (e) {
      FridayLogger.error(LogCategory.assistant, 'AppLauncherRepository getRecentApps error: $e');
      return [];
    }
  }

  @override
  Future<void> recordAppLaunch(String packageName) async {
    try {
      final db = await DatabaseService.instance.database;
      final nowMs = DateTime.now().millisecondsSinceEpoch;
      await db.rawUpdate('''
        UPDATE installed_apps 
        SET launch_count = launch_count + 1, last_launched = ?
        WHERE package_name = ?
      ''', [nowMs, packageName]);
      FridayLogger.log(LogCategory.action, 'AppLauncherRepository: recorded launch for $packageName');
    } catch (e) {
      FridayLogger.error(LogCategory.assistant, 'AppLauncherRepository recordAppLaunch error: $e');
    }
  }
}
