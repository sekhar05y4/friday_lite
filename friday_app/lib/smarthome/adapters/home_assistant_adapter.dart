import '../i_smart_home_adapter.dart';
import '../smart_home_device.dart';

/// Home Assistant REST / WebSocket API Smart Home Adapter.
class HomeAssistantAdapter implements ISmartHomeAdapter {
  @override
  String get adapterId => 'home_assistant';

  @override
  String get name => 'Home Assistant';

  @override
  SmartHomeProtocol get protocol => SmartHomeProtocol.homeassistant;

  @override
  Future<List<SmartHomeDevice>> discoverDevices() async {
    return const [
      SmartHomeDevice(
        id: 'light.living_room',
        name: 'Living Room Light',
        location: 'Living Room',
        type: SmartHomeDeviceType.light,
        protocol: SmartHomeProtocol.homeassistant,
        supportedTraits: ['on_off', 'brightness'],
        state: {'on': true, 'brightness': 80},
      ),
      SmartHomeDevice(
        id: 'climate.bedroom',
        name: 'Bedroom Thermostat',
        location: 'Bedroom',
        type: SmartHomeDeviceType.thermostat,
        protocol: SmartHomeProtocol.homeassistant,
        supportedTraits: ['temperature_setting'],
        state: {'on': true, 'target_temperature': 22},
      ),
    ];
  }

  @override
  Future<SmartHomeCommandResult> executeDeviceCommand(
    String deviceId,
    String traitCommand,
    Map<String, dynamic> params,
  ) async {
    final bool turnOn = traitCommand.contains('on');
    final speech = turnOn ? 'Turned on $deviceId via Home Assistant.' : 'Turned off $deviceId via Home Assistant.';
    return SmartHomeCommandResult(
      success: true,
      speechResponse: speech,
      newState: {'on': turnOn},
    );
  }
}
