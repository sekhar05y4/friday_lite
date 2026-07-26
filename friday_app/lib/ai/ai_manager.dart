import '../interfaces/i_ai_provider.dart';
import '../models/command_result.dart';
import '../models/intent_result.dart';
import '../repositories/settings_repository.dart';
import '../utils/logger.dart';
import 'ai_context_manager.dart';
import 'gemini_provider.dart';
import 'local_llm_provider.dart';

/// Central AI Manager for FRIDAY.
///
/// Ensures no UI widget or action module ever communicates directly with Gemini
/// or any AI provider. All AI interactions flow through [AIManager.instance.active].
///
/// Always obtains context through [AIContextManager] before communicating with [IAIProvider].
///
/// Pluggable architecture supporting:
///   - [GeminiProvider] (default cloud AI provider)
///   - [LocalLLMProvider] (100% offline local LLM / Ollama / llama.cpp provider)
class AIManager {
  AIManager._() {
    _activeProvider = GeminiProvider();
    _initFromSettings();
  }

  static final AIManager instance = AIManager._();

  late IAIProvider _activeProvider;

  /// The active AI provider contract.
  IAIProvider get active => _activeProvider;

  Future<void> _initFromSettings() async {
    final providerId = await SettingsRepository.instance.getAiProvider();
    setProviderById(providerId);
  }

  /// Switch the active AI provider at runtime by ID ('gemini' or 'local_llm').
  void setProviderById(String providerId) {
    if (_activeProvider.providerId == providerId) return;

    final IAIProvider newProvider;
    if (providerId == 'local_llm') {
      newProvider = LocalLLMProvider();
    } else {
      newProvider = GeminiProvider();
    }

    FridayLogger.log(
      LogCategory.api,
      'AIManager: switching provider from ${_activeProvider.providerId} to ${newProvider.providerId}',
    );

    _activeProvider.dispose();
    _activeProvider = newProvider;
    SettingsRepository.instance.setAiProvider(providerId);
  }

  /// Switch the active AI provider directly.
  void setProvider(IAIProvider provider) {
    FridayLogger.log(
      LogCategory.api,
      'AIManager: switching provider from ${_activeProvider.providerId} to ${provider.providerId}',
    );
    _activeProvider.dispose();
    _activeProvider = provider;
    SettingsRepository.instance.setAiProvider(provider.providerId);
  }

  /// Process an unmatched user prompt through the active AI provider.
  ///
  /// Flow:
  ///   1. Obtain full [AIContext] via [AIContextManager].
  ///   2. Call [detectIntent] or [chat] on the active provider.
  ///   3. Return a structured, pattern-matchable [CommandResult].
  Future<CommandResult> processInput(String input) async {
    FridayLogger.log(
      LogCategory.api,
      'AIManager: processing input via ${_activeProvider.providerId}: "$input"',
    );

    try {
      // 1. Always obtain context through AIContextManager first
      final aiContext = await AIContextManager.instance.getContext(historyLimit: 6);

      // 2. Fetch intent classification
      final rawMap = await _activeProvider.detectIntent(input);
      final intentResult = IntentResult.fromMap(rawMap);

      // If backend classified prompt as free-form CHAT or gave an empty speech response,
      // fallback to multi-turn conversation using context history
      if (intentResult.intent == 'CHAT' && intentResult.speechResponse.isEmpty) {
        final formattedHistory = aiContext.toFormattedHistory();
        final reply = await _activeProvider.chat(input, formattedHistory);
        return ActionSuccess(speechResponse: reply);
      }

      final response = intentResult.speechResponse.isNotEmpty
          ? intentResult.speechResponse
          : "I processed your request, but have no speech response.";

      return ActionSuccess(
        speechResponse: response,
        data: {
          'provider': _activeProvider.providerId,
          'intent': intentResult.intent,
          'parameters': intentResult.parameters,
          'confidence': intentResult.confidence,
        },
      );
    } catch (e) {
      FridayLogger.error(LogCategory.api, 'AIManager processInput error: $e');
      return const ActionError(
        userFriendlyMessage: "I encountered an error communicating with the AI service.",
      );
    }
  }

  /// Dispose active AI provider resources on app shutdown.
  void dispose() {
    _activeProvider.dispose();
    FridayLogger.log(LogCategory.api, 'AIManager: disposed');
  }
}
