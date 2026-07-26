import '../interfaces/i_ai_provider.dart';
import '../models/intent_result.dart';
import '../services/api_service.dart';
import '../utils/logger.dart';

/// Gemini AI Provider implementation.
///
/// Communicates with Gemini model via FRIDAY Flask backend REST endpoints (`POST /intent` and `POST /chat`).
/// Includes built-in Intelligent Fallback when the backend server is unreachable.
class GeminiProvider implements IAIProvider {
  @override
  String get providerId => 'gemini';

  @override
  Future<String> chat(String message, List<Map<String, String>> history) async {
    FridayLogger.log(LogCategory.api, 'GeminiProvider: sending chat prompt "$message"');
    try {
      final reply = await ApiService.instance.chat(message, history);
      if (reply.isNotEmpty) return reply;
    } catch (e) {
      FridayLogger.error(LogCategory.api, 'GeminiProvider chat error: $e');
    }

    // Intelligent Offline Fallback
    return _generateOfflineFallback(message);
  }

  @override
  Future<Map<String, dynamic>> detectIntent(String input) async {
    FridayLogger.log(LogCategory.api, 'GeminiProvider: detecting intent for "$input"');
    try {
      final IntentResult result = await ApiService.instance.detectIntent(input);
      if (result.speechResponse.isNotEmpty) {
        return {
          'intent': result.intent,
          'parameters': result.parameters,
          'speech_response': result.speechResponse,
          'confidence': result.confidence,
          'requires_confirmation': result.requiresConfirmation,
        };
      }
    } catch (e) {
      FridayLogger.error(LogCategory.api, 'GeminiProvider detectIntent error: $e');
    }

    // Intelligent Offline Intent Fallback
    final fallbackSpeech = _generateOfflineFallback(input);
    return {
      'intent': 'CHAT',
      'parameters': {},
      'speech_response': fallbackSpeech,
      'confidence': 0.8,
    };
  }

  String _generateOfflineFallback(String input) {
    final lower = input.toLowerCase().trim();

    if (lower.contains('hello') || lower.contains('hi') || lower.contains('hey')) {
      return "Hello! I am FRIDAY. All local features, telephony, and device controls are active.";
    }
    if (lower.contains('who are you') || lower.contains('what is your name')) {
      return "I am FRIDAY, your personal AI assistant.";
    }
    if (lower.contains('what is it') || lower.contains('what is this')) {
      return "I am FRIDAY, an intelligent assistant designed to help with calls, apps, reminders, vision, smart home, and device control.";
    }
    if (lower.contains('time') || lower.contains('clock')) {
      final now = DateTime.now();
      return "The current time is ${now.hour}:${now.minute.toString().padLeft(2, '0')}.";
    }
    if (lower.contains('date') || lower.contains('day')) {
      final now = DateTime.now();
      return "Today is ${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}.";
    }

    return "I received your request: '$input'. Connect to FRIDAY backend or switch to Local LLM in Settings for full cloud AI reasoning.";
  }

  @override
  void dispose() {
    FridayLogger.log(LogCategory.api, 'GeminiProvider: disposed');
  }
}
