/// API configuration constants.
/// All URLs and endpoints are centralized here.
/// Never hardcode these values elsewhere in the codebase.
class ApiConfig {
  ApiConfig._();

  /// Base URL of the Friday backend Flask server.
  /// Override via [SettingsRepository] at runtime.
  static const String defaultBaseUrl = 'http://10.0.2.2:5000';

  // --- Endpoints ---
  static const String intentEndpoint = '/intent';
  static const String chatEndpoint = '/chat';
  static const String weatherEndpoint = '/weather';
  static const String healthEndpoint = '/health';
  static const String settingsEndpoint = '/settings';

  /// Timeout for all API requests in milliseconds.
  static const int requestTimeoutMs = 15000;
}
