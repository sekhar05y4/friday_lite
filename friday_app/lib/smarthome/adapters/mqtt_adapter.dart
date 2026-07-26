import '../i_smart_home_adapter.dart';
import '../smart_home_device.dart';

/// MQTT IoT Broker Smart Home Adapter Plugin.
class MQTTAdapter implements ISmartHomeAdapter {
  @override
  String get adapterId => 'mqtt';

  @override
  String get name => 'MQTT IoT Broker';

  @override
  SmartHomeProtocol get protocol => SmartHomeProtocol.mqtt;

  @override
  Future<List<SmartHomeDevice>> discoverDevices() async {
    return const [
      SmartHomeDevice(
        id: 'mqtt/sensor/temperature',
        name: 'Balcony Temp Sensor',
        location: 'Balcony',
        type: SmartHomeDeviceType.sensor,
        protocol: SmartHomeProtocol.mqtt,
        supportedTraits: ['sensor_reading'],
        state: {'temperature': 24.5},
      ),
    ];
  }

  @override
  Future<SmartHomeCommandResult> executeDeviceCommand(
    String deviceId,
    String traitCommand,
    Map<String, dynamic> params,
  ) async {
    return const SmartHomeCommandResult(
      success: true,
      speechResponse: 'Published MQTT payload.',
      newState: {'status': 'published'},
    );
  }
}
