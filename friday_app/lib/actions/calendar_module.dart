import '../core/event_bus.dart';
import '../core/events.dart';
import '../interfaces/i_action_module.dart';
import '../models/command_result.dart';
import '../models/module_capability.dart';
import '../repositories/calendar_repository.dart';
import '../utils/date_utils.dart';
import '../utils/logger.dart';

/// Productivity Action Module for Calendar Events & Schedule.
class CalendarModule implements IActionModule {
  @override
  String get moduleId => 'calendar';

  @override
  String getDescription() => 'Schedules events and reports upcoming calendar agenda.';

  @override
  ModuleCapability get capability => ModuleCapability(
        name: moduleId,
        description: getDescription(),
        supportedCommands: const [
          'calendar',
          'schedule',
          'add event',
          'upcoming schedule',
          'what is on my schedule',
        ],
      );

  @override
  bool canHandle(String input) {
    final lower = input.toLowerCase().trim();
    return lower.startsWith('calendar') ||
        lower.startsWith('schedule') ||
        lower.startsWith('add event') ||
        lower.contains('upcoming schedule') ||
        lower.contains('on my schedule') ||
        lower.contains('my calendar');
  }

  @override
  Future<CommandResult> execute(String input, Map<String, dynamic> params) async {
    final lower = input.toLowerCase().trim();

    // ── 1. View Agenda / Schedule ──────────────────────────────────────────
    if (lower.contains('schedule') || lower.contains('calendar') || lower.contains('agenda')) {
      final events = await CalendarRepository.instance.getUpcomingEvents(limit: 5);

      if (events.isEmpty) {
        return const ActionSuccess(
          speechResponse: 'You have no upcoming events on your schedule.',
          data: {'count': 0},
        );
      }

      final firstTitle = events.first['title'] as String;
      final startTime = DateTime.fromMillisecondsSinceEpoch(events.first['start_time'] as int);
      final timeStr = FridayDateUtils.formatShort(startTime);
      final speech = 'You have ${events.length} upcoming event${events.length > 1 ? 's' : ''}. Next event: "$firstTitle" ($timeStr).';

      return ActionSuccess(
        speechResponse: speech,
        data: {'events': events},
      );
    }

    // ── 2. Add Calendar Event ──────────────────────────────────────────────
    final rawEvent = lower
        .replaceFirst(RegExp(r'^(add event|schedule meeting|schedule event|schedule)\s*'), '')
        .trim();

    if (rawEvent.isEmpty) {
      return const ActionError(
        userFriendlyMessage: 'What event would you like me to schedule?',
      );
    }

    final startTime = FridayDateUtils.parseNaturalTime(rawEvent) ??
        DateTime.now().add(const Duration(days: 1));
    final timeStr = FridayDateUtils.formatShort(startTime);

    final id = await CalendarRepository.instance.addEvent(rawEvent, startTime);

    FridayLogger.log(
      LogCategory.action,
      'CalendarModule: added event #$id "$rawEvent" at $timeStr',
    );

    EventBus.instance.fire(CommandExecutedEvent(
      moduleId: moduleId,
      success: id > 0,
      speechResponse: 'Scheduled "$rawEvent" for $timeStr.',
    ));

    final speech = 'Scheduled event "$rawEvent" for $timeStr.';
    return ActionSuccess(
      speechResponse: speech,
      data: {'id': id, 'title': rawEvent, 'startTime': startTime.toIso8601String()},
    );
  }

  @override
  void dispose() {}
}
