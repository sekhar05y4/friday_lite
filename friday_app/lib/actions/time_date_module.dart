import '../interfaces/i_action_module.dart';
import '../models/command_result.dart';
import '../models/module_capability.dart';
import '../utils/date_utils.dart';
import '../utils/logger.dart';

/// Local action module to report system time and date.
class TimeDateModule implements IActionModule {
  @override
  String get moduleId => 'time_date';

  @override
  String getDescription() => 'Reports the current system time and date.';

  @override
  ModuleCapability get capability => ModuleCapability(
        name: moduleId,
        description: getDescription(),
        supportedCommands: const ['time', 'date', 'what time', 'what day'],
      );

  @override
  bool canHandle(String input) {
    final lower = input.toLowerCase().trim();
    return lower == 'time' ||
        lower == 'date' ||
        lower.contains('what time') ||
        lower.contains('current time') ||
        lower.contains('what day') ||
        lower.contains('what is the date') ||
        lower.contains('today\'s date');
  }

  @override
  Future<CommandResult> execute(String input, Map<String, dynamic> params) async {
    final now = DateTime.now();
    final timeStr = FridayDateUtils.formatShort(now);

    FridayLogger.log(LogCategory.action, 'TimeDateModule: timeStr = $timeStr');

    return ActionSuccess(
      speechResponse: 'It is currently $timeStr.',
      data: {'timestamp': now.toIso8601String(), 'formatted': timeStr},
    );
  }

  @override
  void dispose() {}
}
