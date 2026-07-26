import '../core/event_bus.dart';
import '../core/events.dart';
import '../interfaces/i_action_module.dart';
import '../models/command_result.dart';
import '../models/module_capability.dart';
import '../repositories/automation_repository.dart';
import '../utils/logger.dart';

/// Automation Engine Action Module for FRIDAY.
class AutomationModule implements IActionModule {
  @override
  String get moduleId => 'automation';

  @override
  String getDescription() =>
      'Creates, manages, and executes automated trigger rules (battery, headphones, geofence, bedtime).';

  @override
  ModuleCapability get capability => ModuleCapability(
        name: moduleId,
        description: getDescription(),
        supportedCommands: const [
          'automation',
          'create automation',
          'show automations',
          'my automations',
          'automation history',
        ],
      );

  @override
  bool canHandle(String input) {
    final lower = input.toLowerCase().trim();
    return lower.startsWith('automation') ||
        lower.contains('create automation') ||
        lower.contains('show automations') ||
        lower.contains('my automations') ||
        lower.contains('automation history');
  }

  @override
  Future<CommandResult> execute(String input, Map<String, dynamic> params) async {
    final lower = input.toLowerCase().trim();

    // ── 1. View Execution History ──────────────────────────────────────────
    if (lower.contains('history')) {
      final logs = await AutomationRepository.instance.getExecutionHistory(limit: 5);
      final speech = logs.isNotEmpty
          ? 'Automation history has ${logs.length} recent entries. Most recent: "${logs.first['rule_name']}".'
          : 'No automation execution history recorded yet.';
      return ActionSuccess(speechResponse: speech, data: {'history': logs});
    }

    // ── 2. List Rules ──────────────────────────────────────────────────────
    if (lower.contains('show') || lower.contains('my automations') || lower == 'automation') {
      final rules = await AutomationRepository.instance.getRules();
      final count = rules.length;
      final speech = count > 0
          ? 'You have $count automation rules configured. First: "${rules.first['name']}".'
          : 'You have no automation rules configured.';
      return ActionSuccess(speechResponse: speech, data: {'rules': rules});
    }

    // ── 3. Create Automation Rule ──────────────────────────────────────────
    // Examples:
    //   "create automation when battery low enable battery saver"
    //   "create automation when headphones connect open spotify"
    //   "create automation when arriving home enable wifi"
    //   "create automation at bedtime silent mode"
    String name = 'Custom Automation';
    String triggerType = 'battery_low';
    String conditionJson = '{"threshold": 20}';
    String actionCmd = 'battery saver';

    if (lower.contains('headphone')) {
      name = 'Headphone Music Rule';
      triggerType = 'headphone_connected';
      conditionJson = '{"state": "connected"}';
      actionCmd = 'open spotify';
    } else if (lower.contains('home')) {
      name = 'Arriving Home Rule';
      triggerType = 'location_arriving_home';
      conditionJson = '{"geofence": "home"}';
      actionCmd = 'open wi-fi settings';
    } else if (lower.contains('bedtime') || lower.contains('night')) {
      name = 'Bedtime Silent Rule';
      triggerType = 'time_bedtime';
      conditionJson = '{"time": "22:00"}';
      actionCmd = 'silent mode';
    }

    final id = await AutomationRepository.instance.createRule(
      name: name,
      triggerType: triggerType,
      conditionJson: conditionJson,
      actionCommand: actionCmd,
    );

    FridayLogger.log(
      LogCategory.action,
      'AutomationModule: created rule #$id "$name" -> "$actionCmd"',
    );

    final speech = 'Automation rule "$name" created. Action: "$actionCmd".';

    EventBus.instance.fire(CommandExecutedEvent(
      moduleId: moduleId,
      success: id > 0,
      speechResponse: speech,
    ));

    return ActionSuccess(
      speechResponse: speech,
      data: {'id': id, 'name': name, 'action': actionCmd},
    );
  }

  @override
  void dispose() {}
}
