import '../interfaces/i_action_module.dart';
import '../utils/logger.dart';

/// Holds all registered [IActionModule] instances and provides discovery.
///
/// Modules are registered once at startup. The [CommandRouter] queries
/// this registry via [findHandler] — no switch statements required.
///
/// ## Registering a new module
/// Import the module and add it to [_modules] below.
/// No other files need to change.
class ModuleRegistry {
  ModuleRegistry._();

  static final ModuleRegistry instance = ModuleRegistry._();

  final List<IActionModule> _modules = [];

  /// Get unmodifiable list of registered modules.
  List<IActionModule> get modules => List.unmodifiable(_modules);

  /// Register all feature modules.
  ///
  /// Called once by [FridayCore.init]. Modules are constructed here and
  /// disposed by [disposeAll] when power mode switches to OFF.
  void registerAll(List<IActionModule> modules) {
    _modules
      ..clear()
      ..addAll(modules);

    FridayLogger.log(
      LogCategory.assistant,
      'ModuleRegistry: registered ${_modules.length} modules — '
      '${_modules.map((m) => m.moduleId).join(', ')}',
    );
  }

  /// Find the first module that claims it can handle [input].
  ///
  /// Returns `null` if no local module matches — the caller should then
  /// fall through to the AI provider.
  IActionModule? findHandler(String input) {
    final normalised = input.toLowerCase().trim();
    for (final module in _modules) {
      if (module.canHandle(normalised)) {
        FridayLogger.log(
          LogCategory.action,
          'ModuleRegistry: "${module.moduleId}" will handle "$normalised"',
        );
        return module;
      }
    }
    return null;
  }

  /// Retrieve a module by its [moduleId] (for direct injection in tests).
  IActionModule? byId(String moduleId) {
    try {
      return _modules.firstWhere((m) => m.moduleId == moduleId);
    } catch (_) {
      return null;
    }
  }

  /// Dispose all modules — called when Power Mode turns OFF.
  void disposeAll() {
    for (final module in _modules) {
      module.dispose();
    }
    FridayLogger.log(LogCategory.assistant, 'ModuleRegistry: all modules disposed');
  }
}
