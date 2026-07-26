import '../i_smart_home_adapter.dart';
import '../smart_home_device.dart';

/// Amazon Alexa Smart Home Adapter Plugin.
class AlexaAdapter implements ISmartHomeAdapter {
  @override
  String get adapterId => 'alexa';

  @override
  String get name => 'Amazon Alexa';

  @override
  SmartHomeProtocol get protocol => SmartHomeProtocol.alexa;

  @override
  Future<List<SmartHomeDevice>> discoverDevices() async {
    return const [
      SmartHomeDevice(
        id: 'alexa_plug_office',
        name: 'Office Smart Plug',
        location: 'Office',
        type: SmartHomeDeviceType.switchDevice,
        protocol: SmartHomeProtocol.alexa,
        supportedTraits: ['on_off'],
        state: {'on': false},
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
      speechResponse: 'Executed Alexa command.',
      newState: {'status': 'executed'},
    );
  }
}
