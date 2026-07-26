import 'dart:convert';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/intent_result.dart';
import '../utils/logger.dart';

/// HTTP client for all communication with the FRIDAY Flask backend.
///
/// All modules and providers use this service — never `http.get/post` directly.
///
/// Responsibilities:
///   - Prepend the base URL (from [SettingsRepository] in Phase 14,
///     hardcoded to [ApiConfig.defaultBaseUrl] for now).
///   - Apply timeout.
///   - Return decoded JSON or throw a structured exception.
class ApiService {
  ApiService._();

  static final ApiService instance = ApiService._();

  /// The active backend base URL. Updated from [SettingsRepository] in Phase 14.
  String _baseUrl = ApiConfig.defaultBaseUrl;

  void setBaseUrl(String url) {
    _baseUrl = url.endsWith('/') ? url.substring(0, url.length - 1) : url;
    FridayLogger.log(LogCategory.api, 'ApiService: base URL set to $_baseUrl');
  }

  // ---------------------------------------------------------------------------
  // Health
  // ---------------------------------------------------------------------------

  /// Ping the backend. Returns `true` if the server responds with status=ok.
  Future<bool> ping() async {
    try {
      final response = await _get(ApiConfig.healthEndpoint);
      return response['status'] == 'ok';
    } catch (_) {
      return false;
    }
  }

  /// Alias for health check.
  Future<bool> checkHealth() => ping();

  // ---------------------------------------------------------------------------
  // Intent detection  (Phase 7)
  // ---------------------------------------------------------------------------

  /// Send [text] to the intent endpoint and return a structured [IntentResult].
  Future<IntentResult> detectIntent(String text) async {
    final body = await _post(ApiConfig.intentEndpoint, {'text': text});
    return IntentResult.fromMap(body);
  }

  // ---------------------------------------------------------------------------
  // Chat  (Phase 7)
  // ---------------------------------------------------------------------------

  /// Send a free-form [message] with [history] to the chat endpoint.
  Future<String> chat(
    String message,
    List<Map<String, String>> history,
  ) async {
    final body = await _post(ApiConfig.chatEndpoint, {
      'message': message,
      'history': history,
    });
    return body['reply'] as String? ?? '';
  }

  // ---------------------------------------------------------------------------
  // Weather  (Phase 13)
  // ---------------------------------------------------------------------------

  /// Fetch weather for [location].
  Future<Map<String, dynamic>> getWeather(String location) async {
    return _get('${ApiConfig.weatherEndpoint}?location=$location');
  }

  // ---------------------------------------------------------------------------
  // Internal HTTP helpers
  // ---------------------------------------------------------------------------

  Future<Map<String, dynamic>> _get(String path) async {
    final uri = Uri.parse('$_baseUrl$path');
    FridayLogger.log(LogCategory.api, 'GET $uri');
    try {
      final response = await http
          .get(uri, headers: _headers)
          .timeout(const Duration(milliseconds: ApiConfig.requestTimeoutMs));
      return _decode(response);
    } on Exception catch (e) {
      FridayLogger.error(LogCategory.api, 'GET $uri failed', error: e);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> _post(
    String path,
    Map<String, dynamic> payload,
  ) async {
    final uri = Uri.parse('$_baseUrl$path');
    FridayLogger.log(LogCategory.api, 'POST $uri payload=$payload');
    try {
      final response = await http
          .post(uri, headers: _headers, body: jsonEncode(payload))
          .timeout(const Duration(milliseconds: ApiConfig.requestTimeoutMs));
      return _decode(response);
    } on Exception catch (e) {
      FridayLogger.error(LogCategory.api, 'POST $uri failed', error: e);
      rethrow;
    }
  }

  Map<String, dynamic> _decode(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw ApiException(
      statusCode: response.statusCode,
      message: response.body,
    );
  }

  static const Map<String, String> _headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };
}

/// Thrown when the backend returns a non-2xx HTTP status.
class ApiException implements Exception {
  final int statusCode;
  final String message;
  const ApiException({required this.statusCode, required this.message});

  @override
  String toString() => 'ApiException($statusCode): $message';
}
