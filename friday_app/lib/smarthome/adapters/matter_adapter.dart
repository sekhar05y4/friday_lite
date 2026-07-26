import '../i_smart_home_adapter.dart';
import '../smart_home_device.dart';

/// Matter / Thread Smart Home Adapter Plugin.
class MatterAdapter implements ISmartHomeAdapter {
  @override
  String get adapterId => 'matter';

  @override
  String get name => 'Matter / Thread';

  @override
  SmartHomeProtocol get protocol => SmartHomeProtocol.matter;

  @override
  Future<List<SmartHomeDevice>> discoverDevices() async {
    return const [
      SmartHomeDevice(
        id: 'matter_lock_frontdoor',
        name: 'Front Door Smart Lock',
        location: 'Entrance',
        type: SmartHomeDeviceType.lock,
        protocol: SmartHomeProtocol.matter,
        supportedTraits: ['lock_unlock'],
        state: {'locked': true},
      ),
    ];
  }

  @override
  Future<SmartHomeCommandResult> executeDeviceCommand(
    String deviceId,
    String traitCommand,
    Map<String, dynamic> params,
  ) async {
    final bool lock = traitCommand.contains('lock');
    return SmartHomeCommandResult(
      success: true,
      speechResponse: lock ? 'Front door locked via Matter protocol.' : 'Front door unlocked via Matter protocol.',
      newState: {'locked': lock},
    );
  }
}
