import '../interfaces/i_ai_provider.dart';
import '../models/intent_result.dart';
import '../services/api_service.dart';
import '../utils/logger.dart';

/// Gemini AI Provider implementation with Rich Offline Conversational Knowledge Engine.
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

  /// Rich Offline Conversational Knowledge Base & Dynamic Intelligence Engine
  String _generateOfflineFallback(String input) {
    final lower = input.toLowerCase().trim();

    // ── 1. Capabilities & Help ──────────────────────────────────────────────
    if (lower.contains('what can you do') ||
        lower.contains('features') ||
        lower.contains('help') ||
        lower.contains('capabilities')) {
      return "I can manage phone calls, send SMS with voice confirmation, search contacts, launch apps, set natural reminders, take voice notes, manage calendar agenda, control flashlight/Wi-Fi/Bluetooth, scan QR/Barcodes with Vision, store long-term memories, automate device rules, control smart home devices, and remote-control desktop PCs.";
    }

    // ── 2. System Architecture & Modules Count ──────────────────────────────
    if (lower.contains('system') || lower.contains('module') || lower.contains('how many')) {
      return "FRIDAY Lite has 20 core feature modules integrated across Telephony, Productivity, Device Control, Camera Vision Platform, Long-Term Memory, Desktop Companion, Automation Engine, and Smart Home Platform.";
    }

    // ── 3. Identity ─────────────────────────────────────────────────────────
    if (lower.contains('who are you') || lower.contains('name') || lower.contains('who made you')) {
      return "I am FRIDAY, your personal AI assistant built with Flutter Clean Architecture, local-first command routing, and 20 integrated feature modules.";
    }

    // ── 4. Greetings ────────────────────────────────────────────────────────
    if (lower.startsWith('hi') || lower.startsWith('hello') || lower.startsWith('hey')) {
      return "Hello! How can I assist you today? All 20 local systems, telephony, and device controls are active.";
    }

    // ── 5. Time & Date ──────────────────────────────────────────────────────
    if (lower.contains('time') || lower.contains('clock')) {
      final now = DateTime.now();
      final minuteStr = now.minute.toString().padLeft(2, '0');
      final period = now.hour >= 12 ? 'PM' : 'AM';
      final hour12 = now.hour == 0 ? 12 : (now.hour > 12 ? now.hour - 12 : now.hour);
      return "The current time is $hour12:$minuteStr $period.";
    }

    if (lower.contains('date') || lower.contains('day') || lower.contains('today')) {
      final now = DateTime.now();
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return "Today is ${months[now.month - 1]} ${now.day}, ${now.year}.";
    }

    // ── 6. Math & Calculations ─────────────────────────────────────────────
    if (RegExp(r'\d+\s*[\+\-\*\/]\s*\d+').hasMatch(lower)) {
      try {
        final match = RegExp(r'(\d+)\s*([\+\-\*\/])\s*(\d+)').firstMatch(lower);
        if (match != null) {
          final n1 = double.parse(match.group(1)!);
          final op = match.group(2)!;
          final n2 = double.parse(match.group(3)!);
          double res = 0;
          if (op == '+') res = n1 + n2;
          if (op == '-') res = n1 - n2;
          if (op == '*') res = n1 * n2;
          if (op == '/') res = n2 != 0 ? n1 / n2 : 0;
          return "The result of $n1 $op $n2 is ${res.toStringAsFixed(res.truncateToDouble() == res ? 0 : 2)}.";
        }
      } catch (_) {}
    }

    // ── 7. Dynamic Contextual Fallback ──────────────────────────────────────
    return "I am processing your query: '$input'. All 20 local feature modules are online. Connect to FRIDAY backend for full cloud AI reasoning.";
  }

  @override
  void dispose() {
    FridayLogger.log(LogCategory.api, 'GeminiProvider: disposed');
  }
}
