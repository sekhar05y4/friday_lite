/// Supported Smart Home Device Types.
enum SmartHomeDeviceType {
  light,
  switchDevice,
  thermostat,
  lock,
  camera,
  sensor,
  generic,
}

/// Supported Smart Home Protocols & Ecosystems.
enum SmartHomeProtocol {
  matter,
  zigbee,
  mqtt,
  ble,
  homeassistant,
  googleHome,
  alexa,
  genericIoT,
}

/// Data model representing a Smart Home Device in FRIDAY's plugin system.
class SmartHomeDevice {
  final String id;
  final String name;
  final String location;
  final SmartHomeDeviceType type;
  final SmartHomeProtocol protocol;
  final List<String> supportedTraits;
  final Map<String, dynamic> state;

  const SmartHomeDevice({
    required this.id,
    required this.name,
    required this.location,
    required this.type,
    required this.protocol,
    required this.supportedTraits,
    required this.state,
  });

  bool get isOn => (state['on'] as bool?) ?? false;

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'location': location,
        'type': type.name,
        'protocol': protocol.name,
        'supportedTraits': supportedTraits,
        'state': state,
      };
}
