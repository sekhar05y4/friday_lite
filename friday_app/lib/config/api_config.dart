import 'package:flutter/foundation.dart';

/// API configuration constants.
/// All URLs and endpoints are centralized here.
class ApiConfig {
  ApiConfig._();

  /// Default Base URL of the Friday backend Flask server.
  /// Automatically picks http://localhost:5000 on Web/Desktop, or http://192.168.1.6:5000 for local Wi-Fi.
  static String get defaultBaseUrl {
    if (kIsWeb) {
      return 'http://127.0.0.1:5000';
    }
    return 'http://192.168.1.6:5000';
  }

  // --- Endpoints ---
  static const String intentEndpoint = '/intent';
  static const String chatEndpoint = '/chat';
  static const String weatherEndpoint = '/weather';
  static const String healthEndpoint = '/health';
  static const String settingsEndpoint = '/settings';

  /// Timeout for all API requests in milliseconds.
  static const int requestTimeoutMs = 15000;
}
