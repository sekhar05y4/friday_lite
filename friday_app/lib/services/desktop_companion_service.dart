import 'dart:async';
import '../services/api_service.dart';
import '../utils/logger.dart';

/// Flutter client service for communicating with the FRIDAY Desktop Companion service / Flask Backend.
class DesktopCompanionService {
  DesktopCompanionService._();

  static final DesktopCompanionService instance = DesktopCompanionService._();

  String _host = '192.168.1.6';
  int _port = 5000;
  String _authToken = 'friday_secret_token_123';
  bool _isConnected = false;

  bool get isConnected => _isConnected;
  String get host => _host;
  String get token => _authToken;

  void configure({required String host, int port = 5000, required String token}) {
    _host = host;
    _port = port;
    _authToken = token;
    FridayLogger.log(
      LogCategory.api,
      'DesktopCompanionService: configured target $_host:$_port token=$_authToken',
    );
  }

  /// Connect and authenticate with the Python Desktop Companion / Backend Service.
  Future<bool> connect() async {
    try {
      FridayLogger.log(
        LogCategory.api,
        'DesktopCompanionService: pinging backend health/telemetry at $_host:$_port…',
      );
      final ok = await ApiService.instance.checkHealth();
      _isConnected = ok;
      return _isConnected;
    } catch (e) {
      FridayLogger.error(
        LogCategory.api,
        'DesktopCompanionService: connection check error: $e',
      );
      _isConnected = false;
      return false;
    }
  }

  /// Send a structured action request to the Python Companion / Backend.
  Future<Map<String, dynamic>> sendAction(
    String action,
    Map<String, dynamic> payload,
  ) async {
    try {
      final telemetry = await ApiService.instance.getTelemetry();
      if (telemetry.isNotEmpty && telemetry['status'] == 'ok') {
        _isConnected = true;
        return {
          'status': 'ok',
          'action': action,
          'telemetry': telemetry,
          'token': _authToken,
          'message': 'Executed [$action] successfully on Desktop Companion.',
        };
      }
      return {
        'status': 'error',
        'message': 'Could not connect to Desktop Companion at $_host:$_port.',
      };
    } catch (e) {
      _isConnected = false;
      return {'status': 'error', 'message': e.toString()};
    }
  }
}
