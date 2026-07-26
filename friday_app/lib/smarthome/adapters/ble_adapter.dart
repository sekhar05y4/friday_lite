import '../i_smart_home_adapter.dart';
import '../smart_home_device.dart';

/// Bluetooth Low Energy (BLE) IoT Device Adapter Plugin.
class BLEDeviceAdapter implements ISmartHomeAdapter {
  @override
  String get adapterId => 'ble';

  @override
  String get name => 'Bluetooth LE IoT';

  @override
  SmartHomeProtocol get protocol => SmartHomeProtocol.ble;

  @override
  Future<List<SmartHomeDevice>> discoverDevices() async {
    return const [
      SmartHomeDevice(
        id: 'ble_fan_bedroom',
        name: 'Bedroom Smart Fan',
        location: 'Bedroom',
        type: SmartHomeDeviceType.switchDevice,
        protocol: SmartHomeProtocol.ble,
        supportedTraits: ['on_off', 'speed'],
        state: {'on': true, 'speed': 2},
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
      speechResponse: 'Executed BLE command.',
      newState: {'status': 'executed'},
    );
  }
}
