import 'events.dart';

/// Represents the current operational state of the FRIDAY assistant.
///
/// Transitions:
///   off  ──► on  (user presses power button or enables via settings)
///   on   ──► off (user says "Friday sleep" or presses power button)
enum PowerMode {
  /// Default state. All services are released. Zero battery consumption.
  off,

  /// Active state. Services are initialised lazily and released after use.
  on,
}

/// Extension helpers for [PowerMode].
extension PowerModeX on PowerMode {
  bool get isOff => this == PowerMode.off;
  bool get isOn => this == PowerMode.on;

  /// Convert to the event-safe value (avoids circular imports).
  PowerModeValue get toEvent =>
      isOff ? PowerModeValue.off : PowerModeValue.on;

  String get label => isOff ? 'OFF' : 'ON';
}
