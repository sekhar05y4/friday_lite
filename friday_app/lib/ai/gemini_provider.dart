import '../interfaces/i_ai_provider.dart';
import '../models/intent_result.dart';
import '../services/api_service.dart';
import '../utils/logger.dart';

/// Gemini AI Provider implementation with Generative Rule Engine & Offline Knowledge Base.
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

  /// Generates domain-specific, informative answers offline instead of repeating identity intros.
  String _generateOfflineFallback(String input) {
    final cleaned = input
        .replaceAll(RegExp(r'([a-zA-Z]{3,})\1+'), r'$1')
        .replaceAll(RegExp(r'\b(\w+)(?:\s+\1)+\b', caseSensitive: false), r'$1')
        .toLowerCase()
        .trim();

    FridayLogger.log(LogCategory.assistant, 'GeminiProvider normalized query: "$cleaned"');

    // ── 1. Capabilities & Feature Breakdown ───────────────────────────────────
    if (cleaned.contains('what can you do') ||
        cleaned.contains('what do you do') ||
        cleaned.contains('do for me') ||
        cleaned.contains('features') ||
        cleaned.contains('help') ||
        cleaned.contains('capabilities')) {
      return "Here is what I can do for you:\n"
             "• Telephony: Make calls, draft SMS with voice confirmation, search contacts.\n"
             "• Productivity: Set natural reminders, record voice notes, manage calendar agenda, alarms & to-do lists.\n"
             "• Device Control: Flashlight, Wi-Fi, Bluetooth, Hotspot, Display brightness, Volume, DND.\n"
             "• Camera Vision: Scan QR codes, barcodes, read text with OCR, detect faces & objects.\n"
             "• Long-Term Memory: Store facts, preferences, knowledge, and task notes.\n"
             "• Desktop Companion: Screenshot PC screen, volume, clipboard sync, execute terminal commands.\n"
             "• Automation Engine & Smart Home: Trigger-condition rules, Matter, Zigbee, Home Assistant, Google, Alexa.";
    }

    // ── 2. System Architecture & Module Breakdown ────────────────────────────
    if (cleaned.contains('system') || cleaned.contains('module') || cleaned.contains('how many')) {
      return "FRIDAY Lite consists of 20 integrated feature systems:\n"
             "1. Phone Call Assistant  2. SMS Voice Assistant  3. Contacts Manager\n"
             "4. Offline Calculator  5. Battery Monitor  6. Device Info & Diagnostics\n"
             "7. Time & Date Engine  8. Voice Notes  9. Reminder Scheduler\n"
             "10. Calendar Agenda  11. Alarm Manager  12. To-Do Checklist\n"
             "13. Clipboard Manager  14. Flashlight & Settings  15. App Launcher\n"
             "16. Camera Vision Platform  17. Long-Term Memory  18. Desktop Companion\n"
             "19. Local LLM Provider  20. Automation Engine  21. Smart Home Platform";
    }

    // ── 3. Identity Queries ──────────────────────────────────────────────────
    if (cleaned == 'who are you' || cleaned == 'what is your name' || cleaned == 'who made you') {
      return "I am FRIDAY, your personal AI assistant. I am built with Flutter Clean Architecture and an offline-first command router to assist you with daily tasks, productivity, device controls, and smart home automation.";
    }

    // ── 4. Instructions / How to Use ──────────────────────────────────────────
    if (cleaned.startsWith('how to') || cleaned.startsWith('how do i')) {
      if (cleaned.contains('call') || cleaned.contains('message') || cleaned.contains('sms')) {
        return "To make a call or send SMS, say 'Call Mom' or 'Message Dad I will be late'. I will verify permissions and ask for your confirmation before sending.";
      }
      if (cleaned.contains('remind') || cleaned.contains('note') || cleaned.contains('calendar')) {
        return "To set reminders or notes, say 'Remind me tomorrow morning at 8 AM to pick up dry cleaning' or 'Note buy coffee'.";
      }
      if (cleaned.contains('scan') || cleaned.contains('vision') || cleaned.contains('camera')) {
        return "Open Settings → Camera Vision Platform to scan QR codes, barcodes, extract text via OCR, or perform object detection.";
      }
      return "You can issue direct voice commands or type prompts in the chat box below. Check Settings → Integrated Feature Modules to explore all 20 modules.";
    }

    // ── 5. Math & Conversions ────────────────────────────────────────────────
    if (RegExp(r'\d+\s*[\+\-\*\/]\s*\d+').hasMatch(cleaned)) {
      try {
        final match = RegExp(r'(\d+)\s*([\+\-\*\/])\s*(\d+)').firstMatch(cleaned);
        if (match != null) {
          final n1 = double.parse(match.group(1)!);
          final op = match.group(2)!;
          final n2 = double.parse(match.group(3)!);
          double res = 0;
          if (op == '+') res = n1 + n2;
          if (op == '-') res = n1 - n2;
          if (op == '*') res = n1 * n2;
          if (op == '/') res = n2 != 0 ? n1 / n2 : 0;
          return "Calculation result: $n1 $op $n2 = ${res.toStringAsFixed(res.truncateToDouble() == res ? 0 : 2)}";
        }
      } catch (_) {}
    }

    // ── 6. Time & Date ───────────────────────────────────────────────────────
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

    // ── 7. Greetings ─────────────────────────────────────────────────────────
    if (cleaned.startsWith('hi') || cleaned.startsWith('hello') || cleaned.startsWith('hey')) {
      return "Hello! How can I assist you today? All 20 local systems are online and ready.";
    }

    // ── 8. Informative Contextual Answer for Unrecognized General Prompts ─────
    return "Regarding '$cleaned': All 20 local assistant modules are ready to execute commands. For full web search and cloud reasoning, test your server connection in Settings or switch to Local LLM mode.";
  }

  @override
  void dispose() {
    FridayLogger.log(LogCategory.api, 'GeminiProvider: disposed');
  }
}
