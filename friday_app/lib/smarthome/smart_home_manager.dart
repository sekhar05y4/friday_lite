import '../utils/logger.dart';
import 'adapters/alexa_adapter.dart';
import 'adapters/ble_adapter.dart';
import 'adapters/google_home_adapter.dart';
import 'adapters/home_assistant_adapter.dart';
import 'adapters/matter_adapter.dart';
import 'adapters/mqtt_adapter.dart';
import 'adapters/zigbee_adapter.dart';
import 'i_smart_home_adapter.dart';
import 'smart_home_device.dart';

/// Central Smart Home Platform Manager for FRIDAY.
///
/// **Plugin-based Architecture**: Provider-specific code is completely isolated
/// inside adapter plugins implementing [ISmartHomeAdapter].
/// **Rule**: No provider-specific code is ever allowed inside FRIDAY Core.
class SmartHomeManager {
  SmartHomeManager._() {
    // Register default ecosystem adapters
    registerAdapter(HomeAssistantAdapter());
    registerAdapter(GoogleHomeAdapter());
    registerAdapter(AlexaAdapter());
    registerAdapter(MQTTAdapter());
    registerAdapter(BLEDeviceAdapter());
    registerAdapter(MatterAdapter());
    registerAdapter(ZigbeeAdapter());
  }

  static final SmartHomeManager instance = SmartHomeManager._();

  final Map<String, ISmartHomeAdapter> _adapters = {};

  /// Register an external Smart Home adapter plugin.
  void registerAdapter(ISmartHomeAdapter adapter) {
    _adapters[adapter.adapterId] = adapter;
    FridayLogger.log(
      LogCategory.assistant,
      'SmartHomeManager: registered adapter "${adapter.name}" (${adapter.adapterId})',
    );
  }

  /// Get list of registered adapter names.
  List<String> get registeredAdapterNames =>
      _adapters.values.map((a) => a.name).toList();

  /// Discover all devices across all registered Smart Home adapters.
  Future<List<SmartHomeDevice>> getAllDevices() async {
    final allDevices = <SmartHomeDevice>[];
    for (final adapter in _adapters.values) {
      try {
        final devices = await adapter.discoverDevices();
        allDevices.addAll(devices);
      } catch (e) {
        FridayLogger.error(
          LogCategory.error,
          'SmartHomeManager: error discovering devices for ${adapter.adapterId}: $e',
        );
      }
    }
    return allDevices;
  }

  /// Execute a voice/automation command on a smart home device.
  Future<SmartHomeCommandResult> executeCommand(
    String deviceIdOrQuery,
    String actionCmd,
  ) async {
    final devices = await getAllDevices();
    final lowerQuery = deviceIdOrQuery.toLowerCase().trim();

    final matchedDevice = devices.firstWhere(
      (d) =>
          d.id.toLowerCase() == lowerQuery ||
          d.name.toLowerCase().contains(lowerQuery) ||
          d.location.toLowerCase().contains(lowerQuery),
      orElse: () => devices.first,
    );

    final adapterId = matchedDevice.protocol == SmartHomeProtocol.homeassistant
        ? 'home_assistant'
        : (matchedDevice.protocol == SmartHomeProtocol.matter
            ? 'matter'
            : matchedDevice.protocol.name);

    final adapter = _adapters[adapterId] ?? _adapters.values.first;

    FridayLogger.log(
      LogCategory.action,
      'SmartHomeManager: executing "$actionCmd" on ${matchedDevice.name} via ${adapter.name}',
    );

    return await adapter.executeDeviceCommand(
      matchedDevice.id,
      actionCmd,
      {},
    );
  }
}
