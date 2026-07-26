import '../core/event_bus.dart';
import '../core/events.dart';
import '../interfaces/i_action_module.dart';
import '../models/command_result.dart';
import '../models/module_capability.dart';
import '../utils/logger.dart';

/// Device Action Module for Flashlight / Torch control.
class FlashlightModule implements IActionModule {
  @override
  String get moduleId => 'flashlight';

  @override
  String getDescription() => 'Toggles or turns on/off device flashlight.';

  @override
  ModuleCapability get capability => ModuleCapability(
        name: moduleId,
        description: getDescription(),
        supportedCommands: const [
          'flashlight',
          'turn on flashlight',
          'turn off flashlight',
          'torch',
        ],
      );

  bool _isOn = false;

  @override
  bool canHandle(String input) {
    final lower = input.toLowerCase().trim();
    return lower.contains('flashlight') || lower.contains('torch');
  }

  @override
  Future<CommandResult> execute(String input, Map<String, dynamic> params) async {
    final lower = input.toLowerCase().trim();
    final turnOff = lower.contains('off') || lower.contains('disable');

    _isOn = !turnOff;
    final speech = _isOn ? 'Turning on flashlight.' : 'Turning off flashlight.';

    FridayLogger.log(LogCategory.action, 'FlashlightModule: state = $_isOn');

    EventBus.instance.fire(CommandExecutedEvent(
      moduleId: moduleId,
      success: true,
      speechResponse: speech,
    ));

    return ActionSuccess(
      speechResponse: speech,
      data: {'state': _isOn},
    );
  }

  @override
  void dispose() {}
}
