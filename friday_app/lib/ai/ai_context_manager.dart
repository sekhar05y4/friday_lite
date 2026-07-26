import '../models/chat_message.dart';
import '../repositories/chat_repository.dart';
import '../repositories/memory_repository.dart';
import '../repositories/settings_repository.dart';
import '../utils/logger.dart';

/// Context object built by [AIContextManager] for the AI provider.
class AIContext {
  final List<ChatMessage> conversationHistory;
  final Map<String, dynamic> memorySummary;
  final List<Map<String, dynamic>> longTermMemories;
  final String activeProviderId;
  final String backendUrl;
  final Map<String, dynamic> sessionState;

  const AIContext({
    required this.conversationHistory,
    required this.memorySummary,
    required this.longTermMemories,
    required this.activeProviderId,
    required this.backendUrl,
    required this.sessionState,
  });

  /// Format conversation history into plain List of Maps for provider APIs.
  List<Map<String, String>> toFormattedHistory() => conversationHistory
      .map((m) => {'role': m.role, 'content': m.content})
      .toList();
}

/// Manages context assembly before communicating with any AI provider.
///
/// Responsibilities:
///   - Retrieve conversation history from [ChatRepository].
///   - Retrieve memory stats & long-term memories from [MemoryRepository].
///   - Retrieve user preferences from [SettingsRepository].
///   - Maintain short-term session state & prepare for long-term vector memory.
///
/// **Crucial Rule**: [AIManager] must always obtain context through
/// [AIContextManager] before dispatching prompts to [IAIProvider].
class AIContextManager {
  AIContextManager._();

  static final AIContextManager instance = AIContextManager._();

  final Map<String, dynamic> _sessionState = {};

  /// Set short-term session state value (e.g. active topic, user location).
  void setSessionValue(String key, dynamic value) {
    _sessionState[key] = value;
    FridayLogger.log(LogCategory.api, 'AIContextManager: session $key = $value');
  }

  /// Get short-term session value.
  dynamic getSessionValue(String key) => _sessionState[key];

  /// Assemble full [AIContext] for an upcoming AI prompt.
  Future<AIContext> getContext({int historyLimit = 6}) async {
    FridayLogger.log(LogCategory.api, 'AIContextManager: assembling AI context…');

    final history =
        await ChatRepository.instance.getRecentMessages(limit: historyLimit);
    final memorySummary =
        await MemoryRepository.instance.getMemorySummary();
    final longTermMemories =
        await MemoryRepository.instance.searchMemory('');
    final providerId =
        await SettingsRepository.instance.getAiProvider();
    final backendUrl =
        await SettingsRepository.instance.getBackendUrl();

    return AIContext(
      conversationHistory: history,
      memorySummary: memorySummary,
      longTermMemories: longTermMemories,
      activeProviderId: providerId,
      backendUrl: backendUrl,
      sessionState: Map.unmodifiable(_sessionState),
    );
  }

  /// Clear in-memory session context.
  void clearSession() {
    _sessionState.clear();
    FridayLogger.log(LogCategory.api, 'AIContextManager: session cleared');
  }
}
