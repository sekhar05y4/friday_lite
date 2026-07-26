import 'dart:async';

/// Lightweight, in-process, type-safe event bus.
///
/// Modules publish and subscribe by event *type* — no string identifiers.
///
/// Usage:
/// ```dart
/// // Subscribe
/// final sub = EventBus.instance.on<SpeechFinishedEvent>().listen((e) { ... });
///
/// // Publish
/// EventBus.instance.fire(SpeechFinishedEvent('hello friday'));
///
/// // Unsubscribe
/// sub.cancel();
/// ```
class EventBus {
  EventBus._();

  static final EventBus instance = EventBus._();

  final StreamController<dynamic> _controller =
      StreamController.broadcast(sync: true);

  /// Publish an event to all subscribers of its type.
  void fire(dynamic event) {
    _controller.add(event);
  }

  /// Subscribe to events of a specific type [T].
  Stream<T> on<T>() {
    return _controller.stream.where((e) => e is T).cast<T>();
  }

  /// Dispose the bus — call only on full app shutdown.
  void dispose() {
    _controller.close();
  }
}
