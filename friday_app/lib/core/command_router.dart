import '../models/command_result.dart';
import '../utils/logger.dart';
import 'module_registry.dart';

/// Implements the local-first routing strategy.
///
/// Flow:
///   1. Check all registered modules via [ModuleRegistry.findHandler].
///   2. If a local module matches → execute immediately (no API call).
///   3. If no local module matches → delegate to the AI router callback
///      which calls [AIManager] and re-routes the structured intent.
///
/// The [CommandRouter] has no knowledge of any specific module or AI provider.
class CommandRouter {
  CommandRouter._();

  static final CommandRouter instance = CommandRouter._();

  /// AI fallback — set once by [FridayCore] during initialisation.
  Future<CommandResult> Function(String input)? _aiRouter;

  /// Register the AI fallback. Called once by [FridayCore.init].
  void setAiRouter(Future<CommandResult> Function(String input) router) {
    _aiRouter = router;
  }

  /// Route [input] to the best available handler.
  ///
  /// Always attempts local resolution first — only calls AI if needed.
  Future<CommandResult> route(String input) async {
    final normalised = input.toLowerCase().trim();

    // ── Local-first check ─────────────────────────────────────────────────
    final localModule = ModuleRegistry.instance.findHandler(normalised);
    if (localModule != null) {
      FridayLogger.log(
        LogCategory.action,
        'CommandRouter: local → ${localModule.moduleId}',
      );
      return localModule.execute(normalised, {});
    }

    // ── AI fallback ───────────────────────────────────────────────────────
    FridayLogger.log(
      LogCategory.action,
      'CommandRouter: no local handler — routing to AI for "$normalised"',
    );

    if (_aiRouter == null) {
      return const ActionError(
        userFriendlyMessage:
            'AI routing is not configured. Please check your settings.',
      );
    }

    return _aiRouter!(normalised);
  }
}
