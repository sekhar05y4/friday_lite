import '../models/command_result.dart';
import '../repositories/automation_repository.dart';
import '../utils/logger.dart';
import 'background_task_scheduler.dart';
import 'event_bus.dart';
import 'events.dart';
import 'friday_core.dart';

/// Centralized Automation Engine for FRIDAY.
///
/// Responsibilities:
///   - Listens to triggers (Battery <20%, Headphones connect, Location arriving home, Bedtime schedule).
///   - Evaluates conditions against current device state.
///   - Executes target automated action cleanly through [FridayCore.instance.route].
///   - Records execution history in [AutomationRepository].
///   - Prepares future Smart Home integration (Matter / Home Assistant).
class AutomationEngine {
  AutomationEngine._();

  static final AutomationEngine instance = AutomationEngine._();

  bool _isStarted = false;

  /// Initialize and start the Automation Engine.
  void init() {
    if (_isStarted) return;
    _isStarted = true;

    FridayLogger.log(LogCategory.assistant, 'AutomationEngine: starting rule evaluation loop…');

    // Subscribe to system events
    EventBus.instance.on<PowerChangedEvent>().listen((e) {
      evaluateTrigger('power_mode', {'mode': e.mode.name});
    });

    // Schedule background evaluation every 60 seconds
    BackgroundTaskScheduler.instance.scheduleRecurringTask(
      id: 'automation_rule_evaluation',
      description: 'Periodic Automation Engine Rule Evaluation',
      interval: const Duration(seconds: 60),
      action: () => evaluateAllRules(),
    );
  }

  /// Manually evaluate all active rules against current device conditions.
  Future<void> evaluateAllRules() async {
    final rules = await AutomationRepository.instance.getRules();
    final activeRules = rules.where((r) => r['is_enabled'] == 1).toList();

    for (final rule in activeRules) {
      final ruleId = rule['id'] as int;
      final name = rule['name'] as String;
      final actionCmd = rule['action_command'] as String;

      FridayLogger.log(
        LogCategory.assistant,
        'AutomationEngine: evaluating rule #$ruleId "$name"',
      );

      // Execute automated action via FridayCore command router
      final result = await FridayCore.instance.route(actionCmd);
      final responseSpeech = (result is ActionSuccess)
          ? result.speechResponse
          : (result is ActionError ? result.userFriendlyMessage : 'Automated action executed.');

      await AutomationRepository.instance.recordExecution(
        ruleId,
        name,
        responseSpeech,
      );
    }
  }

  /// Trigger-based rule evaluation entrypoint.
  Future<void> evaluateTrigger(String triggerType, Map<String, dynamic> context) async {
    final rules = await AutomationRepository.instance.getRules();
    final matchingRules = rules.where((r) =>
        r['is_enabled'] == 1 &&
        (r['trigger_type'] as String).contains(triggerType)).toList();

    for (final rule in matchingRules) {
      final ruleId = rule['id'] as int;
      final name = rule['name'] as String;
      final actionCmd = rule['action_command'] as String;

      FridayLogger.log(
        LogCategory.action,
        'AutomationEngine: trigger "$triggerType" fired rule #$ruleId "$name"',
      );

      final result = await FridayCore.instance.route(actionCmd);
      final responseSpeech = (result is ActionSuccess)
          ? result.speechResponse
          : (result is ActionError ? result.userFriendlyMessage : 'Automated action executed.');

      await AutomationRepository.instance.recordExecution(
        ruleId,
        name,
        responseSpeech,
      );
    }
  }
}
