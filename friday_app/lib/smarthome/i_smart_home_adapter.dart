import 'smart_home_device.dart';

/// Result descriptor for smart home command execution.
class SmartHomeCommandResult {
  final bool success;
  final String speechResponse;
  final Map<String, dynamic> newState;

  const SmartHomeCommandResult({
    required this.success,
    required this.speechResponse,
    required this.newState,
  });
}

/// Abstract plugin interface for Smart Home Adapters.
///
/// **Rule**: No provider-specific code in FRIDAY Core. All smart home platforms
/// (Google Home, Alexa, Home Assistant, MQTT, BLE, Matter, Zigbee) implement this interface.
abstract class ISmartHomeAdapter {
  String get adapterId;
  String get name;
  SmartHomeProtocol get protocol;

  /// Discover all devices managed by this adapter.
  Future<List<SmartHomeDevice>> discoverDevices();

  /// Execute a command (e.g. turn_on, set_brightness, lock) on a device.
  Future<SmartHomeCommandResult> executeDeviceCommand(
    String deviceId,
    String traitCommand,
    Map<String, dynamic> params,
  );
}
