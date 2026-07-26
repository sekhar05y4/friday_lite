import 'package:flutter/foundation.dart';

import '../interfaces/i_action_module.dart';
import '../models/command_result.dart';
import '../utils/logger.dart';
import 'capability_manager.dart';
import 'event_bus.dart';
import 'events.dart';
import 'module_registry.dart';
import 'command_router.dart';
import 'power_mode.dart';

/// The FRIDAY Core — single entry point for all assistant operations.
///
/// Responsibilities (and nothing more):
///   - Manage Power Mode state machine (OFF ↔ ON).
///   - Initialise and teardown services lazily.
///   - Load modules into [ModuleRegistry].
///   - Wire [CommandRouter] with the AI fallback.
///   - Publish [PowerChangedEvent] via [EventBus].
///
/// **No business logic lives here.** The Core delegates everything to
/// modules, services, and the AI manager.
class FridayCore extends ChangeNotifier {
  FridayCore._();

  static final FridayCore instance = FridayCore._();

  PowerMode _powerMode = PowerMode.off;

  /// Current power mode. Observe via [context.watch<FridayCore>()] or
  /// subscribe to [PowerChangedEvent] on the [EventBus].
  PowerMode get powerMode => _powerMode;

  // ---------------------------------------------------------------------------
  // Initialisation
  // ---------------------------------------------------------------------------

  /// Initialise the Core once at app startup.
  ///
  /// Registers [modules] and wires the [aiRouter] callback.
  /// Does NOT turn the assistant ON — it starts in OFF mode.
  Future<void> init({
    required List<IActionModule> modules,
    required Future<CommandResult> Function(String) aiRouter,
  }) async {
    FridayLogger.log(LogCategory.assistant, 'FridayCore: initialising…');

    ModuleRegistry.instance.registerAll(modules);
    CapabilityManager.instance.refresh();
    CommandRouter.instance.setAiRouter(aiRouter);

    FridayLogger.log(LogCategory.assistant, 'FridayCore: ready (OFF mode)');
  }

  // ---------------------------------------------------------------------------
  // Power Mode
  // ---------------------------------------------------------------------------

  /// Switch to ON mode. Publishes [PowerChangedEvent].
  Future<void> powerOn() async {
    if (_powerMode.isOn) return;
    _powerMode = PowerMode.on;
    FridayLogger.log(LogCategory.assistant, 'FridayCore: power ON');
    EventBus.instance.fire(PowerChangedEvent(_powerMode.toEvent));
    notifyListeners();
  }

  /// Switch to OFF mode. Disposes all modules and publishes [PowerChangedEvent].
  ///
  /// **Battery contract**: releases every resource immediately.
  Future<void> powerOff() async {
    if (_powerMode.isOff) return;
    _powerMode = PowerMode.off;
    FridayLogger.log(
      LogCategory.assistant,
      'FridayCore: power OFF — disposing all module resources',
    );
    ModuleRegistry.instance.disposeAll();
    EventBus.instance.fire(PowerChangedEvent(_powerMode.toEvent));
    notifyListeners();
  }

  /// Toggle between ON and OFF.
  Future<void> togglePower() async =>
      _powerMode.isOff ? powerOn() : powerOff();

  // ---------------------------------------------------------------------------
  // Command routing
  // ---------------------------------------------------------------------------

  /// Route a user [command] through the local-first [CommandRouter].
  ///
  /// Returns `null` and logs a warning if power is OFF.
  Future<CommandResult?> route(String command) async {
    if (_powerMode.isOff) {
      FridayLogger.log(
        LogCategory.action,
        'FridayCore: command ignored — power is OFF',
      );
      return null;
    }
    return CommandRouter.instance.route(command);
  }

  // ---------------------------------------------------------------------------
  // Shutdown
  // ---------------------------------------------------------------------------

  /// Full teardown — call only when the app is closing.
  Future<void> shutdown() async {
    await powerOff();
    EventBus.instance.dispose();
    FridayLogger.log(LogCategory.assistant, 'FridayCore: shutdown complete');
  }
}
