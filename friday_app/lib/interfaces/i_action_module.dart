import '../models/command_result.dart';
import '../models/module_capability.dart';

/// Contract that every FRIDAY action plugin must implement.
///
/// The [ModuleRegistry] discovers and holds instances of all [IActionModule]s.
/// The [CommandRouter] calls [canHandle] on each registered module to find the
/// best handler for a given user input — no switch statements needed.
///
/// ## Adding a new module
/// 1. Create a class that implements [IActionModule].
/// 2. Register it in [ModuleRegistry.modules].
/// 3. Done — no other files need to change.
abstract class IActionModule {
  /// Unique, machine-readable identifier for this module.
  ///
  /// Example: `'app_launcher'`, `'battery'`, `'weather'`
  String get moduleId;

  /// Short human-readable description of what this module does.
  ///
  /// Used for logging and future "help" commands.
  String getDescription();

  /// Capability descriptor for dynamic capability discovery.
  ModuleCapability get capability;

  /// Returns `true` if this module can handle [input] **locally**,
  /// without an AI API call.
  ///
  /// Keep this method fast — it is called synchronously on every input.
  bool canHandle(String input);

  /// Execute the user's request and return a structured [CommandResult].
  ///
  /// [params] contains structured parameters extracted by the AI when
  /// the command was first routed through [AIManager] (may be empty for
  /// locally-handled commands).
  Future<CommandResult> execute(String input, Map<String, dynamic> params);

  /// Release all resources held by this module.
  ///
  /// Called by [FridayCore] when Power Mode switches to OFF.
  void dispose();
}
