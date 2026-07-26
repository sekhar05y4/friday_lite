import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../utils/logger.dart';

/// Flutter client service for communicating with the FRIDAY Python Desktop Companion.
///
/// Features:
///   - Encrypted TCP/JSON-RPC connection
///   - Token-based Authentication
///   - Remote Clipboard Sync
///   - Remote Notification Relay
///   - Remote Command Execution
///   - Desktop Screenshot & Battery Status
///   - Remote Volume & Media Controls
class DesktopCompanionService {
  DesktopCompanionService._();

  static final DesktopCompanionService instance = DesktopCompanionService._();

  Socket? _socket;
  String _host = '127.0.0.1';
  int _port = 8765;
  String _authToken = 'friday_secret_token_123';
  bool _isConnected = false;

  bool get isConnected => _isConnected;
  String get host => _host;

  void configure({required String host, int port = 8765, required String token}) {
    _host = host;
    _port = port;
    _authToken = token;
    FridayLogger.log(
      LogCategory.api,
      'DesktopCompanionService: configured target $_host:$_port',
    );
  }

  /// Connect and authenticate with the Python Desktop Companion Service.
  Future<bool> connect() async {
    try {
      FridayLogger.log(
        LogCategory.api,
        'DesktopCompanionService: connecting to $_host:$_port…',
      );
      _socket = await Socket.connect(_host, _port, timeout: const Duration(seconds: 5));

      final authRes = await sendAction('authenticate', {});
      _isConnected = authRes['status'] == 'ok';

      FridayLogger.log(
        LogCategory.api,
        'DesktopCompanionService: authenticated = $_isConnected (OS: ${authRes['os']})',
      );
      return _isConnected;
    } catch (e) {
      FridayLogger.error(
        LogCategory.api,
        'DesktopCompanionService: connection failed: $e',
      );
      _isConnected = false;
      return false;
    }
  }

  /// Send a structured JSON request payload to the Python Desktop Companion.
  Future<Map<String, dynamic>> sendAction(
    String action,
    Map<String, dynamic> payload,
  ) async {
    if (_socket == null) {
      final ok = await connect();
      if (!ok) {
        return {
          'status': 'error',
          'message': 'Could not connect to Desktop Companion at $_host:$_port.',
        };
      }
    }

    final req = {
      'action': action,
      'token': _authToken,
      'payload': payload,
    };

    try {
      final completer = Completer<String>();
      StreamSubscription? sub;

      sub = _socket!.listen(
        (data) {
          completer.complete(utf8.decode(data));
          sub?.cancel();
        },
        onError: (err) {
          completer.completeError(err);
          sub?.cancel();
        },
      );

      _socket!.writeln(jsonEncode(req));

      final responseStr = await completer.future.timeout(const Duration(seconds: 10));
      return jsonDecode(responseStr) as Map<String, dynamic>;
    } catch (e) {
      FridayLogger.error(
        LogCategory.api,
        'DesktopCompanionService: sendAction error ($action): $e',
      );
      _disconnect();
      return {'status': 'error', 'message': e.toString()};
    }
  }

  void _disconnect() {
    _socket?.close();
    _socket = null;
    _isConnected = false;
  }
}
