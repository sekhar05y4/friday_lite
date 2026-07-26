import 'package:android_intent_plus/android_intent.dart';
import 'package:android_intent_plus/flag.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/event_bus.dart';
import '../core/events.dart';
import '../interfaces/i_action_module.dart';
import '../models/command_result.dart';
import '../models/module_capability.dart';
import '../repositories/app_launcher_repository.dart';
import '../utils/logger.dart';

/// Intelligent App Launcher Action Module for FRIDAY.
///
/// Features:
///   - Exact and fuzzy app matching ("Open Instagram", "Play Spotify", "Open Flutter project")
///   - Category-based app launching ("Play music", "Open social media")
///   - Installed apps database & search ("Search installed apps")
///   - Usage statistics tracking & Favorites ("Most used apps", "Recent apps")
///   - Android intent & web fallback launching
class AppLauncherModule implements IActionModule {
  @override
  String get moduleId => 'app_launcher';

  @override
  String getDescription() =>
      'Launches installed applications using exact, fuzzy, or category matching.';

  @override
  ModuleCapability get capability => ModuleCapability(
        name: moduleId,
        description: getDescription(),
        supportedCommands: const [
          'open',
          'launch',
          'start',
          'play',
          'search installed apps',
          'recent apps',
          'most used apps',
        ],
      );

  @override
  bool canHandle(String input) {
    final lower = input.toLowerCase().trim();
    return lower.startsWith('open ') ||
        lower.startsWith('launch ') ||
        lower.startsWith('start ') ||
        lower.startsWith('play ') ||
        lower.contains('search installed apps') ||
        lower.contains('recent apps') ||
        lower.contains('most used apps') ||
        lower.contains('favorite apps');
  }

  @override
  Future<CommandResult> execute(String input, Map<String, dynamic> params) async {
    final lower = input.toLowerCase().trim();

    // ── 1. Usage stats: Most used / Recent apps / Search ───────────────────
    if (lower.contains('most used apps') || lower.contains('favorite apps')) {
      final apps = await AppLauncherRepository.instance.getMostUsedApps(limit: 5);
      final names = apps.map((a) => a['app_name'] as String).join(', ');
      final speech = apps.isNotEmpty
          ? 'Your most used apps are: $names.'
          : 'No app usage data available yet.';

      return ActionSuccess(speechResponse: speech, data: {'apps': apps});
    }

    if (lower.contains('recent apps')) {
      final apps = await AppLauncherRepository.instance.getRecentApps(limit: 5);
      final names = apps.map((a) => a['app_name'] as String).join(', ');
      final speech = apps.isNotEmpty
          ? 'Recently launched apps: $names.'
          : 'No recently launched apps recorded.';

      return ActionSuccess(speechResponse: speech, data: {'apps': apps});
    }

    if (lower.contains('search installed apps')) {
      final query = lower.replaceFirst('search installed apps', '').trim();
      final apps = await AppLauncherRepository.instance.searchApps(query);
      final count = apps.length;
      final speech = count > 0
          ? 'Found $count matching app${count > 1 ? 's' : ''}: ${apps.first['app_name']}.'
          : 'No matching apps found in installed database.';

      return ActionSuccess(speechResponse: speech, data: {'apps': apps});
    }

    // ── 2. Extract target application name ────────────────────────────────
    String targetApp = lower
        .replaceFirst(RegExp(r'^(open|launch|start|play)\s+'), '')
        .trim();

    if (targetApp.isEmpty) {
      return const ActionError(
        userFriendlyMessage: 'Which application would you like me to open?',
      );
    }

    // Category resolution (e.g. "play music" -> spotify, "open social" -> instagram/whatsapp)
    if (targetApp.contains('music') || targetApp.contains('song')) {
      targetApp = 'spotify';
    } else if (targetApp.contains('social')) {
      targetApp = 'instagram';
    }

    FridayLogger.log(LogCategory.action, 'AppLauncherModule: searching database for "$targetApp"');

    // ── 3. Database Search & Fuzzy Matching ────────────────────────────────
    final dbApps = await AppLauncherRepository.instance.searchApps(targetApp);
    String? matchedPackage;
    String matchedName = targetApp;

    if (dbApps.isNotEmpty) {
      matchedPackage = dbApps.first['package_name'] as String;
      matchedName = dbApps.first['app_name'] as String;
    }

    // ── 4. Launch via Package Intent ───────────────────────────────────────
    if (matchedPackage != null && matchedPackage != 'dev.flutter.app') {
      try {
        final intent = AndroidIntent(
          action: 'action_main',
          category: 'category_launcher',
          package: matchedPackage,
          flags: <int>[Flag.FLAG_ACTIVITY_NEW_TASK],
        );
        await intent.launch();

        // Record launch statistics
        await AppLauncherRepository.instance.recordAppLaunch(matchedPackage);

        final speech = 'Opening $matchedName.';
        EventBus.instance.fire(CommandExecutedEvent(
          moduleId: moduleId,
          success: true,
          speechResponse: speech,
        ));

        return ActionSuccess(
          speechResponse: speech,
          data: {'package': matchedPackage, 'app': matchedName},
        );
      } catch (e) {
        FridayLogger.error(LogCategory.action, 'Failed package launch for $matchedPackage: $e');
      }
    }

    // ── 5. Special Fallback Intents ─────────────────────────────────────────
    if (targetApp.contains('camera')) {
      const intent = AndroidIntent(action: 'android.media.action.IMAGE_CAPTURE');
      await intent.launch();
      return const ActionSuccess(speechResponse: 'Opening Camera.');
    }

    if (targetApp.contains('settings')) {
      const intent = AndroidIntent(action: 'android.settings.SETTINGS');
      await intent.launch();
      return const ActionSuccess(speechResponse: 'Opening Settings.');
    }

    // Web scheme launch fallback (e.g. instagram.com, spotify.com)
    final webUrl = 'https://$targetApp.com';
    if (await canLaunchUrl(Uri.parse(webUrl))) {
      await launchUrl(Uri.parse(webUrl));
      final speech = 'Opening $targetApp.';

      EventBus.instance.fire(CommandExecutedEvent(
        moduleId: moduleId,
        success: true,
        speechResponse: speech,
      ));

      return ActionSuccess(
        speechResponse: speech,
        data: {'target': targetApp},
      );
    }

    return ActionSuccess(
      speechResponse: 'Attempting to launch $matchedName.',
      data: {'target': matchedName},
    );
  }

  @override
  void dispose() {}
}
