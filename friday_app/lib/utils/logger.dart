/// Structured logger for FRIDAY Lite.
///
/// Logs are categorised and suppressed in release builds (except errors).
/// Never use [print] directly in the codebase — always use [FridayLogger].
///
/// Usage:
/// ```dart
/// FridayLogger.log(LogCategory.action, 'AppLauncher: opening Chrome');
/// FridayLogger.error(LogCategory.api, 'Gemini timeout', error: e);
/// ```
library friday_logger;

import 'package:flutter/foundation.dart';

/// Categories of log messages.
enum LogCategory {
  /// Core assistant lifecycle events.
  assistant,

  /// Module action execution events.
  action,

  /// STT / TTS events.
  speech,

  /// API / network requests.
  api,

  /// Non-fatal warnings.
  warning,

  /// Errors and exceptions.
  error,
}

class FridayLogger {
  FridayLogger._();

  /// Log an informational message.
  ///
  /// In release builds, only [LogCategory.error] is emitted.
  static void log(LogCategory category, String message, {dynamic data}) {
    if (kReleaseMode) return;
    final tag = '[FRIDAY/${category.name.toUpperCase()}]';
    debugPrint('$tag $message${data != null ? ' | $data' : ''}');
  }

  /// Log an error — emitted in both debug and release builds.
  static void error(
    LogCategory category,
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    final tag = '[FRIDAY/${category.name.toUpperCase()}][ERROR]';
    debugPrint('$tag $message${error != null ? ' | $error' : ''}');
    if (stackTrace != null && !kReleaseMode) {
      debugPrint(stackTrace.toString());
    }
  }
}
