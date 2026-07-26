import '../core/event_bus.dart';
import '../core/events.dart';
import '../interfaces/i_action_module.dart';
import '../models/command_result.dart';
import '../models/module_capability.dart';
import '../services/desktop_companion_service.dart';
import '../utils/logger.dart';

/// Desktop Companion Action Module for FRIDAY Mobile.
class DesktopCompanionModule implements IActionModule {
  @override
  String get moduleId => 'desktop_companion';

  @override
  String getDescription() =>
      'Controls remote desktop companion: clipboard sync, commands, screenshot, volume, and media.';

  @override
  ModuleCapability get capability => ModuleCapability(
        name: moduleId,
        description: getDescription(),
        supportedCommands: const [
          'desktop screenshot',
          'desktop volume',
          'desktop battery',
          'desktop clipboard',
          'run desktop command',
          'open desktop app',
          'desktop media',
        ],
      );

  @override
  bool canHandle(String input) {
    final lower = input.toLowerCase().trim();
    return lower.startsWith('desktop ') ||
        lower.contains('desktop screenshot') ||
        lower.contains('desktop volume') ||
        lower.contains('desktop battery') ||
        lower.contains('desktop clipboard') ||
        lower.contains('desktop app');
  }

  @override
  Future<CommandResult> execute(String input, Map<String, dynamic> params) async {
    final lower = input.toLowerCase().trim();

    FridayLogger.log(LogCategory.action, 'DesktopCompanionModule: executing "$lower"');

    // ── 1. Screenshot ──────────────────────────────────────────────────────
    if (lower.contains('screenshot')) {
      final res = await DesktopCompanionService.instance.sendAction('screenshot', {});
      if (res['status'] == 'ok') {
        const speech = 'Desktop screenshot captured successfully.';
        EventBus.instance.fire(CommandExecutedEvent(
          moduleId: moduleId,
          success: true,
          speechResponse: speech,
        ));
        return ActionSuccess(speechResponse: speech, data: res);
      }
    }

    // ── 2. Battery Status ──────────────────────────────────────────────────
    if (lower.contains('battery')) {
      final res = await DesktopCompanionService.instance.sendAction('battery_status', {});
      if (res['status'] == 'ok') {
        final battery = res['battery'] as Map<String, dynamic>? ?? {};
        final level = battery['level'] ?? 85;
        final speech = 'Desktop battery level is $level percent.';
        return ActionSuccess(speechResponse: speech, data: res);
      }
    }

    // ── 3. Volume Control ──────────────────────────────────────────────────
    if (lower.contains('volume')) {
      final direction = lower.contains('up')
          ? 'up'
          : (lower.contains('down') ? 'down' : 'mute');
      final res = await DesktopCompanionService.instance.sendAction('volume_control', {'direction': direction});
      if (res['status'] == 'ok') {
        final speech = 'Adjusted desktop volume: $direction.';
        return ActionSuccess(speechResponse: speech, data: res);
      }
    }

    // ── 4. Clipboard Sync ──────────────────────────────────────────────────
    if (lower.contains('clipboard')) {
      final res = await DesktopCompanionService.instance.sendAction('clipboard_get', {});
      if (res['status'] == 'ok') {
        final text = res['clipboard'] as String? ?? '';
        final speech = text.isNotEmpty
            ? 'Desktop clipboard content: "$text".'
            : 'Desktop clipboard is empty.';
        return ActionSuccess(speechResponse: speech, data: res);
      }
    }

    // ── 5. Run Command ─────────────────────────────────────────────────────
    if (lower.contains('run command') || lower.startsWith('desktop run ')) {
      final cmd = lower.replaceFirst(RegExp(r'^(desktop run command|run desktop command|desktop run)\s*'), '').trim();
      final res = await DesktopCompanionService.instance.sendAction('run_command', {'command': cmd});
      if (res['status'] == 'ok') {
        const speech = 'Executed command on desktop.';
        return ActionSuccess(speechResponse: speech, data: res);
      }
    }

    // ── 6. Open Desktop Application ────────────────────────────────────────
    if (lower.contains('open app') || lower.contains('launch')) {
      final appName = lower.replaceFirst(RegExp(r'^(desktop open app|open desktop app|desktop open)\s*'), '').trim();
      final res = await DesktopCompanionService.instance.sendAction('open_app', {'app_name': appName});
      if (res['status'] == 'ok') {
        final speech = 'Opened $appName on desktop.';
        return ActionSuccess(speechResponse: speech, data: res);
      }
    }

    // Fallback ping test
    final res = await DesktopCompanionService.instance.sendAction('authenticate', {});
    final isOk = res['status'] == 'ok';
    final speech = isOk
        ? 'Connected to desktop companion running on ${res['os'] ?? 'OS'}.'
        : 'Could not connect to desktop companion service.';

    return ActionSuccess(speechResponse: speech, data: res);
  }

  @override
  void dispose() {}
}
