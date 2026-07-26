import '../i_smart_home_adapter.dart';
import '../smart_home_device.dart';

/// Google Home Smart Home Adapter Plugin.
class GoogleHomeAdapter implements ISmartHomeAdapter {
  @override
  String get adapterId => 'google_home';

  @override
  String get name => 'Google Home';

  @override
  SmartHomeProtocol get protocol => SmartHomeProtocol.googleHome;

  @override
  Future<List<SmartHomeDevice>> discoverDevices() async {
    return const [
      SmartHomeDevice(
        id: 'gh_speaker_kitchen',
        name: 'Kitchen Speaker',
        location: 'Kitchen',
        type: SmartHomeDeviceType.generic,
        protocol: SmartHomeProtocol.googleHome,
        supportedTraits: ['volume', 'media'],
        state: {'on': true, 'volume': 50},
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
      speechResponse: 'Executed Google Home command.',
      newState: {'status': 'executed'},
    );
  }
}
