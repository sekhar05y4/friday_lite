import 'package:battery_plus/battery_plus.dart';

import '../interfaces/i_action_module.dart';
import '../models/command_result.dart';
import '../models/module_capability.dart';
import '../utils/logger.dart';

/// Local action module to read device battery status and level.
class BatteryModule implements IActionModule {
  @override
  String get moduleId => 'battery';

  @override
  String getDescription() => 'Reads device battery level and charging state.';

  @override
  ModuleCapability get capability => ModuleCapability(
        name: moduleId,
        description: getDescription(),
        supportedCommands: const ['battery', 'battery level', 'battery percentage'],
      );

  final Battery _battery = Battery();

  @override
  bool canHandle(String input) {
    final lower = input.toLowerCase().trim();
    return lower.contains('battery') ||
        lower.contains('battery level') ||
        lower.contains('battery percentage') ||
        lower.contains('how much power');
  }

  @override
  Future<CommandResult> execute(String input, Map<String, dynamic> params) async {
    try {
      final level = await _battery.batteryLevel;
      final state = await _battery.batteryState;

      final stateString = switch (state) {
        BatteryState.charging => 'and is currently charging.',
        BatteryState.discharging => 'and is discharging.',
        BatteryState.full => 'and is fully charged.',
        BatteryState.connectedNotCharging => 'and connected to power.',
        BatteryState.unknown => '.',
      };

      FridayLogger.log(
        LogCategory.action,
        'BatteryModule: level=$level%, state=$state',
      );

      return ActionSuccess(
        speechResponse: 'Your battery is at $level percent $stateString',
        data: {'level': level, 'state': state.name},
      );
    } catch (e) {
      FridayLogger.error(LogCategory.action, 'Failed to fetch battery info: $e');
      return const ActionError(
        userFriendlyMessage: 'Could not read battery level.',
      );
    }
  }

  @override
  void dispose() {}
}
