/// Contract for all AI provider implementations.
///
/// The [AIManager] factory always returns an [IAIProvider].
/// UI code and modules never reference a concrete provider (e.g. GeminiProvider)
/// directly — they always go through [AIManager.active].
///
/// ## Adding a new provider
/// 1. Create a class that implements [IAIProvider].
/// 2. Change the active provider in [AIManager] config.
/// 3. Done.
abstract class IAIProvider {
  /// Unique identifier for this AI provider (e.g. 'gemini', 'openai', 'ollama', 'local_llm', 'custom').
  String get providerId;

  /// Send a free-form chat message with conversation [history] context
  /// and return the assistant's reply as a plain string.
  Future<String> chat(String message, List<Map<String, String>> history);

  /// Analyse [input] and return a structured intent result.
  ///
  /// The result is a map with at minimum:
  ///   - `intent`           (String)
  ///   - `parameters`       (Map<String, dynamic>)
  ///   - `speech_response`  (String)
  ///   - `confidence`       (double)
  Future<Map<String, dynamic>> detectIntent(String input);

  /// Release any held resources (e.g. HTTP clients, subscriptions).
  void dispose();
}
