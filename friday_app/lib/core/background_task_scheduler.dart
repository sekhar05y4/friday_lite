import 'dart:async';

import '../utils/logger.dart';
import 'event_bus.dart';
import 'events.dart';

/// Scheduled task metadata descriptor.
class ScheduledTask {
  final String id;
  final String description;
  final DateTime scheduledAt;
  final VoidCallback action;

  ScheduledTask({
    required this.id,
    required this.description,
    required this.scheduledAt,
    required this.action,
  });
}

typedef VoidCallback = void Function();

/// Centralized Background Task Scheduler for FRIDAY.
///
/// Responsibilities:
///   - Reminder execution and alarm scheduling.
///   - Background database & cache cleanup.
///   - Wake-word detection hooks.
///   - Periodic synchronization tasks.
///
/// **Rule**: Individual feature modules must NEVER create ad-hoc [Timer] objects.
/// All periodic or delayed actions must be scheduled through [BackgroundTaskScheduler.instance].
class BackgroundTaskScheduler {
  BackgroundTaskScheduler._();

  static final BackgroundTaskScheduler instance = BackgroundTaskScheduler._();

  final Map<String, Timer> _activeTimers = {};
  final Map<String, ScheduledTask> _scheduledTasks = {};

  /// Schedule a one-time delayed task.
  void scheduleTask({
    required String id,
    required String description,
    required Duration delay,
    required VoidCallback action,
  }) {
    cancelTask(id);

    final scheduledTime = DateTime.now().add(delay);
    final task = ScheduledTask(
      id: id,
      description: description,
      scheduledAt: scheduledTime,
      action: action,
    );

    _scheduledTasks[id] = task;

    _activeTimers[id] = Timer(delay, () {
      FridayLogger.log(
        LogCategory.assistant,
        'BackgroundTaskScheduler: executing task "$id" ($description)',
      );
      try {
        action();
      } catch (e) {
        FridayLogger.error(
          LogCategory.error,
          'BackgroundTaskScheduler: task "$id" failed',
          error: e,
        );
        EventBus.instance.fire(ErrorOccurredEvent(
          source: 'BackgroundTaskScheduler/$id',
          message: e.toString(),
        ));
      } finally {
        _scheduledTasks.remove(id);
        _activeTimers.remove(id);
      }
    });

    FridayLogger.log(
      LogCategory.assistant,
      'BackgroundTaskScheduler: scheduled "$id" in ${delay.inSeconds}s',
    );
  }

  /// Schedule a recurring background task.
  void scheduleRecurringTask({
    required String id,
    required String description,
    required Duration interval,
    required VoidCallback action,
  }) {
    cancelTask(id);

    _activeTimers[id] = Timer.periodic(interval, (_) {
      FridayLogger.log(
        LogCategory.assistant,
        'BackgroundTaskScheduler: executing recurring task "$id"',
      );
      try {
        action();
      } catch (e) {
        FridayLogger.error(
          LogCategory.error,
          'BackgroundTaskScheduler: recurring task "$id" failed',
          error: e,
        );
      }
    });

    FridayLogger.log(
      LogCategory.assistant,
      'BackgroundTaskScheduler: scheduled recurring task "$id" every ${interval.inSeconds}s',
    );
  }

  /// Schedule a reminder execution.
  void scheduleReminder({
    required int reminderId,
    required String title,
    required DateTime scheduledAt,
  }) {
    final now = DateTime.now();
    final delay = scheduledAt.isAfter(now)
        ? scheduledAt.difference(now)
        : const Duration(milliseconds: 100);

    scheduleTask(
      id: 'reminder_$reminderId',
      description: 'Reminder: $title',
      delay: delay,
      action: () {
        EventBus.instance.fire(ReminderTriggeredEvent(
          reminderId: reminderId,
          title: title,
        ));
      },
    );
  }

  /// Cancel an active or scheduled task.
  void cancelTask(String id) {
    _activeTimers[id]?.cancel();
    _activeTimers.remove(id);
    _scheduledTasks.remove(id);
  }

  /// Cancel all active tasks — called on Power Mode OFF.
  void cancelAll() {
    for (final timer in _activeTimers.values) {
      timer.cancel();
    }
    _activeTimers.clear();
    _scheduledTasks.clear();
    FridayLogger.log(
      LogCategory.assistant,
      'BackgroundTaskScheduler: cancelled all background tasks',
    );
  }

  /// Active scheduled tasks summary for diagnostics.
  List<Map<String, dynamic>> getActiveTaskSummaries() {
    return _scheduledTasks.values
        .map((t) => {
              'id': t.id,
              'description': t.description,
              'scheduledAt': t.scheduledAt.toIso8601String(),
            })
        .toList();
  }

  int get activeTaskCount => _activeTimers.length;
}
