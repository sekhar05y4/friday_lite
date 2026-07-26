import '../interfaces/i_ai_provider.dart';
import '../models/intent_result.dart';
import '../services/api_service.dart';
import '../utils/logger.dart';

/// Gemini AI Provider implementation.
///
/// Communicates with the Gemini model via the FRIDAY Flask backend's REST endpoints
/// (`POST /intent` and `POST /chat`).
///
/// **Lazy initialisation**: network calls only happen when [detectIntent] or [chat]
/// are explicitly invoked. Never initializes or consumes battery when idle.
class GeminiProvider implements IAIProvider {
  @override
  String get providerId => 'gemini';

  @override
  Future<String> chat(String message, List<Map<String, String>> history) async {
    FridayLogger.log(LogCategory.api, 'GeminiProvider: sending chat prompt "$message"');
    try {
      final reply = await ApiService.instance.chat(message, history);
      return reply.isNotEmpty ? reply : "I am connected to Gemini, but received an empty response.";
    } on ApiException catch (e) {
      FridayLogger.error(LogCategory.api, 'GeminiProvider API error: ${e.message}');
      return "I could not reach Gemini AI. Error code: ${e.statusCode}.";
    } catch (e) {
      FridayLogger.error(LogCategory.api, 'GeminiProvider chat error: $e');
      return "I could not reach the Gemini backend. Please check your connection.";
    }
  }

  @override
  Future<Map<String, dynamic>> detectIntent(String input) async {
    FridayLogger.log(LogCategory.api, 'GeminiProvider: detecting intent for "$input"');
    try {
      final IntentResult result = await ApiService.instance.detectIntent(input);
      return {
        'intent': result.intent,
        'parameters': result.parameters,
        'speech_response': result.speechResponse,
        'confidence': result.confidence,
        'requires_confirmation': result.requiresConfirmation,
      };
    } on ApiException catch (e) {
      FridayLogger.error(LogCategory.api, 'GeminiProvider intent API error: ${e.message}');
      return {
        'intent': 'CHAT',
        'parameters': {},
        'speech_response': "I encountered an error processing your request with Gemini (HTTP ${e.statusCode}).",
        'confidence': 0.0,
      };
    } catch (e) {
      FridayLogger.error(LogCategory.api, 'GeminiProvider detectIntent error: $e');
      return {
        'intent': 'CHAT',
        'parameters': {},
        'speech_response': "I am having trouble reaching the AI server right now.",
        'confidence': 0.0,
      };
    }
  }

  @override
  void dispose() {
    FridayLogger.log(LogCategory.api, 'GeminiProvider: disposed');
  }
}
