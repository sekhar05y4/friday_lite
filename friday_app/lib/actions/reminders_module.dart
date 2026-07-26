import '../core/background_task_scheduler.dart';
import '../core/event_bus.dart';
import '../core/events.dart';
import '../interfaces/i_action_module.dart';
import '../models/command_result.dart';
import '../models/module_capability.dart';
import '../repositories/reminders_repository.dart';
import '../utils/date_utils.dart';
import '../utils/logger.dart';

/// Productivity Action Module for Reminders & Alarms.
class RemindersModule implements IActionModule {
  @override
  String get moduleId => 'reminders';

  @override
  String getDescription() => 'Saves, schedules, and manages natural-language reminders.';

  @override
  ModuleCapability get capability => ModuleCapability(
        name: moduleId,
        description: getDescription(),
        supportedCommands: const [
          'remind me',
          'set reminder',
          'show reminders',
          'my reminders',
        ],
      );

  @override
  bool canHandle(String input) {
    final lower = input.toLowerCase().trim();
    return lower.startsWith('remind') ||
        lower.startsWith('set reminder') ||
        lower.startsWith('show reminders') ||
        lower.startsWith('my reminders');
  }

  @override
  Future<CommandResult> execute(String input, Map<String, dynamic> params) async {
    final lower = input.toLowerCase().trim();

    // ── 1. Show Reminders ──────────────────────────────────────────────────
    if (lower == 'show reminders' || lower == 'my reminders') {
      final reminders = await RemindersRepository.instance.getPendingReminders();

      if (reminders.isEmpty) {
        return const ActionSuccess(
          speechResponse: 'You have no pending reminders.',
          data: {'count': 0},
        );
      }

      final count = reminders.length;
      final firstTitle = reminders.first.title;
      final timeStr = FridayDateUtils.formatShort(reminders.first.scheduledAt);
      final speech = 'You have $count pending reminder${count > 1 ? 's' : ''}. Next: "$firstTitle" ($timeStr).';

      return ActionSuccess(
        speechResponse: speech,
        data: {'reminders': reminders.map((r) => r.toMap()).toList()},
      );
    }

    // ── 2. Create Reminder ─────────────────────────────────────────────────
    final rawTask = lower
        .replaceFirst(RegExp(r'^(remind me to|set reminder to|set reminder|remind me)\s*'), '')
        .trim();

    if (rawTask.isEmpty) {
      return const ActionError(
        userFriendlyMessage: 'What would you like me to remind you about?',
      );
    }

    // Parse natural language date/time
    final scheduledTime = FridayDateUtils.parseNaturalTime(rawTask) ??
        DateTime.now().add(const Duration(hours: 1));

    final timeStr = FridayDateUtils.formatShort(scheduledTime);

    // Save to SQLite (survives app restart)
    final id = await RemindersRepository.instance.createReminder(rawTask, scheduledTime);

    // Schedule background task execution
    if (id > 0) {
      BackgroundTaskScheduler.instance.scheduleReminder(
        reminderId: id,
        title: rawTask,
        scheduledAt: scheduledTime,
      );
    }

    FridayLogger.log(
      LogCategory.action,
      'RemindersModule: scheduled reminder #$id "$rawTask" for $timeStr',
    );

    // Publish ReminderCreatedEvent to EventBus
    EventBus.instance.fire(ReminderCreatedEvent(
      title: rawTask,
      scheduledAt: scheduledTime,
    ));

    final speech = 'Reminder set for $rawTask ($timeStr).';
    return ActionSuccess(
      speechResponse: speech,
      data: {
        'id': id,
        'title': rawTask,
        'scheduledAt': scheduledTime.toIso8601String(),
      },
    );
  }

  @override
  void dispose() {}
}
