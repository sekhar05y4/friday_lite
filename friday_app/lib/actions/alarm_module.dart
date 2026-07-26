import '../core/event_bus.dart';
import '../core/events.dart';
import '../interfaces/i_action_module.dart';
import '../models/command_result.dart';
import '../models/module_capability.dart';
import '../repositories/alarm_repository.dart';
import '../utils/date_utils.dart';
import '../utils/logger.dart';

/// Productivity Action Module for Alarms.
class AlarmModule implements IActionModule {
  @override
  String get moduleId => 'alarm';

  @override
  String getDescription() => 'Sets and lists local device alarms.';

  @override
  ModuleCapability get capability => ModuleCapability(
        name: moduleId,
        description: getDescription(),
        supportedCommands: const [
          'set alarm',
          'wake me up',
          'show alarms',
          'my alarms',
        ],
      );

  @override
  bool canHandle(String input) {
    final lower = input.toLowerCase().trim();
    return lower.startsWith('set alarm') ||
        lower.startsWith('wake me up') ||
        lower.startsWith('show alarms') ||
        lower.startsWith('my alarms') ||
        lower.contains('alarm');
  }

  @override
  Future<CommandResult> execute(String input, Map<String, dynamic> params) async {
    final lower = input.toLowerCase().trim();

    // ── 1. View Alarms ─────────────────────────────────────────────────────
    if (lower == 'show alarms' || lower == 'my alarms') {
      final alarms = await AlarmRepository.instance.getAlarms();

      if (alarms.isEmpty) {
        return const ActionSuccess(
          speechResponse: 'You have no active alarms set.',
          data: {'count': 0},
        );
      }

      final label = alarms.first['label'] as String;
      final alarmTime = DateTime.fromMillisecondsSinceEpoch(alarms.first['alarm_time'] as int);
      final timeStr = FridayDateUtils.formatShort(alarmTime);
      final speech = 'You have ${alarms.length} alarm${alarms.length > 1 ? 's' : ''}. Next alarm: "$label" ($timeStr).';

      return ActionSuccess(
        speechResponse: speech,
        data: {'alarms': alarms},
      );
    }

    // ── 2. Set Alarm ───────────────────────────────────────────────────────
    final rawTime = lower
        .replaceFirst(RegExp(r'^(set alarm for|set alarm|wake me up at|wake me up)\s*'), '')
        .trim();

    final alarmTime = FridayDateUtils.parseNaturalTime(rawTime) ??
        DateTime.now().add(const Duration(hours: 8));

    final timeStr = FridayDateUtils.formatShort(alarmTime);
    final label = rawTime.isNotEmpty ? rawTime : 'Alarm';

    final id = await AlarmRepository.instance.setAlarm(label, alarmTime);

    FridayLogger.log(
      LogCategory.action,
      'AlarmModule: set alarm #$id "$label" at $timeStr',
    );

    EventBus.instance.fire(CommandExecutedEvent(
      moduleId: moduleId,
      success: id > 0,
      speechResponse: 'Alarm set for $timeStr.',
    ));

    final speech = 'Alarm set for $timeStr.';
    return ActionSuccess(
      speechResponse: speech,
      data: {'id': id, 'label': label, 'alarmTime': alarmTime.toIso8601String()},
    );
  }

  @override
  void dispose() {}
}
