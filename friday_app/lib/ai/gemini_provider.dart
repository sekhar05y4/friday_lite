import '../interfaces/i_ai_provider.dart';
import '../models/intent_result.dart';
import '../services/api_service.dart';
import '../utils/logger.dart';

/// Gemini AI Provider implementation with Intelligent Normalizer & Offline Engine.
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
          'confidence': result.confidence,
          'speech_response': result.speechResponse,
          'requires_confirmation': result.requiresConfirmation,
        };
      }
    } catch (e) {
      FridayLogger.error(LogCategory.api, 'GeminiProvider detectIntent error: $e');
    }

    final fallbackSpeech = _generateOfflineFallback(input);
    return {
      'intent': 'CHAT',
      'parameters': {},
      'speech_response': fallbackSpeech,
      'confidence': 0.85,
    };
  }

  /// Normalises stuttered/repeated speech input and generates dynamic offline answers.
  String _generateOfflineFallback(String input) {
    // 1. Clean and deduplicate repeated words (e.g. "whatwhatwhat canwhat can you" -> "what can you")
    final cleaned = input
        .replaceAll(RegExp(r'([a-zA-Z]+)\1+'), r'$1')
        .replaceAll(RegExp(r'\b(\w+)(?:\s+\1)+\b', caseSensitive: false), r'$1')
        .toLowerCase()
        .trim();

    FridayLogger.log(LogCategory.assistant, 'GeminiProvider normalized speech: "$cleaned"');

    // ── Capabilities & What can you do ────────────────────────────────────
    if (cleaned.contains('what can you do') ||
        cleaned.contains('what do you do') ||
        cleaned.contains('do for me') ||
        cleaned.contains('features') ||
        cleaned.contains('help') ||
        cleaned.contains('capabilities')) {
      return "I can place phone calls, draft SMS messages, search contacts, launch apps, set reminders, manage your calendar & to-do list, control flashlight & device settings, scan QR/barcodes with Vision, store long-term memories, automate rules, and control smart home devices.";
    }

    // ── Systems & Modules Count ───────────────────────────────────────────
    if (cleaned.contains('system') ||
        cleaned.contains('module') ||
        cleaned.contains('how many')) {
      return "FRIDAY Lite consists of 20 integrated local systems covering Telephony, Productivity, Device Control, Camera Vision, Long-Term Memory, Desktop Companion, Automation Engine, and Smart Home Platform.";
    }

    // ── Identity & Who are you ──────────────────────────────────────────────
    if (cleaned.contains('who are you') ||
        cleaned.contains('your name') ||
        cleaned.contains('what is it') ||
        cleaned.contains('what is this')) {
      return "I am FRIDAY, your advanced AI assistant. I handle your daily tasks, phone calls, device controls, and smart home automation.";
    }

    // ── Greetings ─────────────────────────────────────────────────────────
    if (cleaned.startsWith('hi') || cleaned.startsWith('hello') || cleaned.startsWith('hey')) {
      return "Hello! I am online and ready to assist you.";
    }

    // ── Time & Date ───────────────────────────────────────────────────────
    if (cleaned.contains('time') || cleaned.contains('clock')) {
      final now = DateTime.now();
      final period = now.hour >= 12 ? 'PM' : 'AM';
      final hour12 = now.hour == 0 ? 12 : (now.hour > 12 ? now.hour - 12 : now.hour);
      return "The current time is $hour12:${now.minute.toString().padLeft(2, '0')} $period.";
    }

    if (cleaned.contains('date') || cleaned.contains('day') || cleaned.contains('today')) {
      final now = DateTime.now();
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return "Today is ${months[now.month - 1]} ${now.day}, ${now.year}.";
    }

    // ── Dynamic intelligent fallback for general queries ──────────────────
    return "I understand you asked: '$cleaned'. All 20 local assistant modules are active. To connect to full Gemini cloud AI, ensure your phone and PC are on the same Wi-Fi and port 5000 is allowed in Windows Firewall.";
  }

  @override
  void dispose() {
    FridayLogger.log(LogCategory.api, 'GeminiProvider: disposed');
  }
}
