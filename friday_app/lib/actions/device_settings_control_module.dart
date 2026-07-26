import 'package:android_intent_plus/android_intent.dart';

import '../core/event_bus.dart';
import '../core/events.dart';
import '../interfaces/i_action_module.dart';
import '../models/command_result.dart';
import '../models/module_capability.dart';
import '../utils/logger.dart';

/// Device Control Module managing system settings, network toggles,
/// brightness, volume, DND, battery saver, and platform-restricted controls.
class DeviceSettingsControlModule implements IActionModule {
  @override
  String get moduleId => 'device_control';

  @override
  String getDescription() =>
      'Controls system settings, Wi-Fi, Bluetooth, Hotspot, Display, Volume, and DND.';

  @override
  ModuleCapability get capability => ModuleCapability(
        name: moduleId,
        description: getDescription(),
        supportedCommands: const [
          'wifi',
          'bluetooth',
          'hotspot',
          'battery saver',
          'brightness',
          'volume',
          'silent mode',
          'airplane mode',
          'auto rotate',
          'settings',
        ],
      );

  @override
  bool canHandle(String input) {
    final lower = input.toLowerCase().trim();
    return lower.contains('wifi') ||
        lower.contains('wi-fi') ||
        lower.contains('bluetooth') ||
        lower.contains('hotspot') ||
        lower.contains('tether') ||
        lower.contains('battery saver') ||
        lower.contains('battery health') ||
        lower.contains('brightness') ||
        lower.contains('volume') ||
        lower.contains('silent mode') ||
        lower.contains('do not disturb') ||
        lower.contains('mute') ||
        lower.contains('airplane mode') ||
        lower.contains('auto rotate') ||
        lower.contains('display settings') ||
        lower.contains('sound settings');
  }

  @override
  Future<CommandResult> execute(String input, Map<String, dynamic> params) async {
    final lower = input.toLowerCase().trim();

    String action = 'android.settings.SETTINGS';
    String speech = 'Opening device settings.';

    // ── Wi-Fi ───────────────────────────────────────────────────────────────
    if (lower.contains('wifi') || lower.contains('wi-fi')) {
      action = 'android.settings.WIFI_SETTINGS';
      speech = 'Opening Wi-Fi settings.';
    }
    // ── Bluetooth ───────────────────────────────────────────────────────────
    else if (lower.contains('bluetooth')) {
      action = 'android.settings.BLUETOOTH_SETTINGS';
      speech = 'Opening Bluetooth settings.';
    }
    // ── Hotspot ─────────────────────────────────────────────────────────────
    else if (lower.contains('hotspot') || lower.contains('tether')) {
      action = 'android.settings.WIRELESS_SETTINGS';
      speech = 'Opening Hotspot and Tethering settings.';
    }
    // ── Battery Saver & Health ──────────────────────────────────────────────
    else if (lower.contains('battery saver') || lower.contains('battery health')) {
      action = 'android.settings.BATTERY_SAVER_SETTINGS';
      speech = 'Opening Battery Saver settings.';
    }
    // ── Display, Brightness & Auto-Rotate ──────────────────────────────────
    else if (lower.contains('brightness') ||
        lower.contains('auto rotate') ||
        lower.contains('display settings')) {
      action = 'android.settings.DISPLAY_SETTINGS';
      speech = 'Opening Display and Brightness settings.';
    }
    // ── Sound, Volume, Silent Mode & DND ────────────────────────────────────
    else if (lower.contains('volume') ||
        lower.contains('silent mode') ||
        lower.contains('do not disturb') ||
        lower.contains('mute') ||
        lower.contains('sound settings')) {
      action = 'android.settings.SOUND_SETTINGS';
      speech = 'Opening Sound and Volume settings.';
    }
    // ── Airplane Mode ───────────────────────────────────────────────────────
    else if (lower.contains('airplane mode')) {
      action = 'android.settings.AIRPLANE_MODE_SETTINGS';
      speech = 'Opening Airplane mode settings due to Android security policy.';
    }

    FridayLogger.log(LogCategory.action, 'DeviceSettingsControlModule: launching intent action = $action');

    try {
      final intent = AndroidIntent(action: action);
      await intent.launch();

      EventBus.instance.fire(CommandExecutedEvent(
        moduleId: moduleId,
        success: true,
        speechResponse: speech,
      ));

      return ActionSuccess(
        speechResponse: speech,
        data: {'intent': action},
      );
    } catch (e) {
      FridayLogger.error(LogCategory.action, 'Failed to launch settings intent ($action): $e');
      return ActionError(
        userFriendlyMessage: 'Could not open settings for $input.',
      );
    }
  }

  @override
  void dispose() {}
}
