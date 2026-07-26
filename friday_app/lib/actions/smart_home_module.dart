import '../core/event_bus.dart';
import '../core/events.dart';
import '../interfaces/i_action_module.dart';
import '../models/command_result.dart';
import '../models/module_capability.dart';
import '../smarthome/smart_home_manager.dart';
import '../utils/logger.dart';

/// Smart Home Action Module for FRIDAY.
///
/// Features:
///   - Control lights, switches, thermostats, locks, and sensors
///     ("turn on living room light", "turn off bedroom fan", "lock front door")
///   - List discovered smart home devices ("show smart home devices")
///   - Plugin architecture: Zero provider-specific code inside FRIDAY Core.
class SmartHomeModule implements IActionModule {
  @override
  String get moduleId => 'smart_home';

  @override
  String getDescription() =>
      'Controls smart home devices via Home Assistant, Google Home, Alexa, Matter, Zigbee, MQTT, and BLE.';

  @override
  ModuleCapability get capability => ModuleCapability(
        name: moduleId,
        description: getDescription(),
        supportedCommands: const [
          'turn on light',
          'turn off light',
          'lock front door',
          'set temperature',
          'show smart home devices',
          'my smart home',
        ],
      );

  @override
  bool canHandle(String input) {
    final lower = input.toLowerCase().trim();
    return lower.contains('light') ||
        lower.contains('thermostat') ||
        lower.contains('smart lock') ||
        lower.contains('lock front door') ||
        lower.contains('smart home') ||
        lower.contains('turn on ') ||
        lower.contains('turn off ');
  }

  @override
  Future<CommandResult> execute(String input, Map<String, dynamic> params) async {
    final lower = input.toLowerCase().trim();

    // ── 1. List Smart Home Devices ─────────────────────────────────────────
    if (lower.contains('show smart home') || lower == 'my smart home' || lower == 'smart home') {
      final devices = await SmartHomeManager.instance.getAllDevices();
      final count = devices.length;
      final names = devices.map((d) => '${d.name} (${d.location})').join(', ');
      final speech = count > 0
          ? 'Found $count smart home device${count > 1 ? 's' : ''}: $names.'
          : 'No smart home devices discovered.';

      return ActionSuccess(
        speechResponse: speech,
        data: {'devices': devices.map((d) => d.toMap()).toList()},
      );
    }

    // ── 2. Device Command Execution ────────────────────────────────────────
    FridayLogger.log(LogCategory.action, 'SmartHomeModule: executing "$lower"');

    final result = await SmartHomeManager.instance.executeCommand(lower, lower);

    EventBus.instance.fire(CommandExecutedEvent(
      moduleId: moduleId,
      success: result.success,
      speechResponse: result.speechResponse,
    ));

    return ActionSuccess(
      speechResponse: result.speechResponse,
      data: result.newState,
    );
  }

  @override
  void dispose() {}
}
