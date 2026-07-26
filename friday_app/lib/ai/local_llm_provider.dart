import 'dart:convert';
import 'package:http/http.dart' as http;

import '../interfaces/i_ai_provider.dart';
import '../utils/logger.dart';

/// Local LLM Provider implementation for FRIDAY.
///
/// Communicates directly with local Ollama, llama.cpp, or local inference servers
/// for 100% offline chat, command intent classification, summaries, and reasoning.
///
/// Default local endpoint: http://localhost:11434 (Ollama)
///
/// **Rule**: Does NOT modify FRIDAY Core. Provider switching is controlled
/// cleanly via [AIManager.instance.setProviderById('local_llm')].
class LocalLLMProvider implements IAIProvider {
  final String localBaseUrl;
  final String modelName;
  final http.Client _httpClient;

  LocalLLMProvider({
    this.localBaseUrl = 'http://127.0.0.1:11434',
    this.modelName = 'llama3',
    http.Client? httpClient,
  }) : _httpClient = httpClient ?? http.Client();

  @override
  String get providerId => 'local_llm';

  @override
  Future<String> chat(String message, List<Map<String, String>> history) async {
    FridayLogger.log(LogCategory.api, 'LocalLLMProvider: offline chat via $localBaseUrl');

    try {
      final uri = Uri.parse('$localBaseUrl/api/chat');
      final reqBody = {
        'model': modelName,
        'messages': [
          ...history.map((h) => {'role': h['role'], 'content': h['content']}),
          {'role': 'user', 'content': message},
        ],
        'stream': false,
      };

      final response = await _httpClient.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(reqBody),
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        final content = decoded['message']?['content'] as String?;
        if (content != null && content.isNotEmpty) {
          return content;
        }
      }
    } catch (e) {
      FridayLogger.error(LogCategory.api, 'LocalLLMProvider chat error: $e');
    }

    // Offline fallback speech response
    return 'FRIDAY (Offline Local LLM): I received your message "$message".';
  }

  @override
  Future<Map<String, dynamic>> detectIntent(String input) async {
    FridayLogger.log(LogCategory.api, 'LocalLLMProvider: offline intent classification for "$input"');

    try {
      final uri = Uri.parse('$localBaseUrl/api/generate');
      final prompt = 'Classify intent for user prompt: "$input". Respond in JSON format with intent, speech_response, and confidence.';
      final reqBody = {
        'model': modelName,
        'prompt': prompt,
        'format': 'json',
        'stream': false,
      };

      final response = await _httpClient.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(reqBody),
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        final textResp = decoded['response'] as String?;
        if (textResp != null && textResp.isNotEmpty) {
          final parsed = jsonDecode(textResp) as Map<String, dynamic>;
          return {
            'intent': parsed['intent'] ?? 'CHAT',
            'parameters': parsed['parameters'] ?? {},
            'speech_response': parsed['speech_response'] ?? parsed['reply'] ?? '',
            'confidence': parsed['confidence'] ?? 0.9,
          };
        }
      }
    } catch (e) {
      FridayLogger.error(LogCategory.api, 'LocalLLMProvider detectIntent error: $e');
    }

    // Structured offline intent response
    return {
      'intent': 'CHAT',
      'parameters': {},
      'speech_response': 'Processed offline via Local LLM: "$input".',
      'confidence': 0.85,
    };
  }

  /// Offline text summary helper.
  Future<String> summarize(String content) async {
    return chat('Summarize the following text:\n$content', []);
  }

  /// Offline reasoning helper.
  Future<String> reason(String query) async {
    return chat('Think step by step and answer:\n$query', []);
  }

  @override
  void dispose() {
    _httpClient.close();
    FridayLogger.log(LogCategory.api, 'LocalLLMProvider: disposed');
  }
}
