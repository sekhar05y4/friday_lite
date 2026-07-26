import 'dart:async';
import 'package:flutter/foundation.dart';

import '../core/event_bus.dart';
import '../core/events.dart';
import '../core/friday_core.dart';
import '../core/power_mode.dart';
import '../models/chat_message.dart';
import '../models/command_result.dart';
import '../repositories/chat_repository.dart';
import '../services/speech_service.dart';
import '../services/tts_service.dart';
import '../utils/logger.dart';

/// Manages the assistant's conversational state and the complete voice pipeline.
///
/// ## Voice pipeline flow
/// ```
/// User taps mic
///   └─► startListening()
///         └─► SpeechService.startListening()
///               └─► SpeechStartedEvent  → status = listening
///               └─► SpeechFinishedEvent → _handleTranscript()
///                     └─► FridayCore.route(transcript)
///                           └─► CommandResult
///                                 └─► TtsService.speak(response)
///                                       └─► status = speaking
///                                       └─► ConversationFinishedEvent
///                                             └─► status = idle
///                                             └─► auto-restart listening
/// ```
///
/// ## Power Mode contract
/// [PowerChangedEvent] OFF → immediately stops mic + TTS, resets status.
class AssistantProvider extends ChangeNotifier {
  AssistantProvider() {
    _subscribeToEvents();
  }

  // Services (injected lazily — allocated only when power is ON)
  final SpeechService _speech = SpeechService.instance;
  final TtsService _tts = TtsService.instance;

  AssistantStatus _status = AssistantStatus.idle;
  // ignore: prefer_final_fields — reassigned by STT interim results
  String _interimText = '';
  final List<AssistantMessage> _messages = [];

  /// Controls whether the assistant automatically re-enters listening
  /// after finishing a conversation turn.
  bool _autoListen = true;

  final List<StreamSubscription<dynamic>> _subscriptions = [];

  // ---------------------------------------------------------------------------
  // Public getters
  // ---------------------------------------------------------------------------

  AssistantStatus get status => _status;
  String get interimText => _interimText;
  List<AssistantMessage> get messages => List.unmodifiable(_messages);
  bool get isListening => _status == AssistantStatus.listening;
  bool get isProcessing => _status == AssistantStatus.processing;
  bool get isSpeaking => _status == AssistantStatus.speaking;
  bool get autoListen => _autoListen;

  set autoListen(bool value) {
    _autoListen = value;
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // EventBus wiring
  // ---------------------------------------------------------------------------

  void _subscribeToEvents() {
    // ── Power changed ─────────────────────────────────────────────────────
    _subscriptions.add(
      EventBus.instance.on<PowerChangedEvent>().listen((event) {
        if (event.mode == PowerModeValue.off) {
          _handlePowerOff();
        } else {
          _handlePowerOn();
        }
      }),
    );

    // ── Speech started ────────────────────────────────────────────────────
    _subscriptions.add(
      EventBus.instance.on<SpeechStartedEvent>().listen((_) {
        _setStatus(AssistantStatus.listening);
      }),
    );

    // ── Speech finished ───────────────────────────────────────────────────
    _subscriptions.add(
      EventBus.instance.on<SpeechFinishedEvent>().listen((event) {
        _interimText = '';
        notifyListeners();
        if (event.transcript.isNotEmpty) {
          _handleTranscript(event.transcript);
        } else {
          // Nothing heard — return to idle
          _setStatus(AssistantStatus.idle);
        }
      }),
    );

    // ── Speech error ──────────────────────────────────────────────────────
    _subscriptions.add(
      EventBus.instance.on<SpeechErrorEvent>().listen((event) {
        _interimText = '';
        addMessage(role: 'assistant', content: event.message);
        _setStatus(AssistantStatus.idle);
      }),
    );

    // ── Conversation finished (TTS done) ──────────────────────────────────
    _subscriptions.add(
      EventBus.instance.on<ConversationFinishedEvent>().listen((_) {
        if (FridayCore.instance.powerMode.isOff) return;
        _setStatus(AssistantStatus.idle);

        // Auto-restart listening for a hands-free experience
        if (_autoListen) {
          Future.delayed(const Duration(milliseconds: 300), () {
            if (FridayCore.instance.powerMode.isOn &&
                _status == AssistantStatus.idle) {
              startListening();
            }
          });
        }
      }),
    );
  }

  // ---------------------------------------------------------------------------
  // Power mode reactions
  // ---------------------------------------------------------------------------

  void _handlePowerOff() {
    FridayLogger.log(LogCategory.assistant, 'AssistantProvider: power OFF');
    _speech.dispose();
    _tts.dispose();
    _status = AssistantStatus.idle;
    _interimText = '';
    notifyListeners();
  }

  void _handlePowerOn() {
    FridayLogger.log(LogCategory.assistant, 'AssistantProvider: power ON');
    _setStatus(AssistantStatus.idle);
    // Initialise TTS eagerly so the first response has no delay
    _tts.initialize();
  }

  // ---------------------------------------------------------------------------
  // Voice pipeline
  // ---------------------------------------------------------------------------

  /// Start a listening session.
  ///
  /// Requests microphone permission, initialises STT, and begins listening.
  Future<void> startListening() async {
    if (FridayCore.instance.powerMode.isOff) return;
    if (_status == AssistantStatus.listening) return;
    if (_status == AssistantStatus.processing ||
        _status == AssistantStatus.speaking) {
      return;
    }

    FridayLogger.log(LogCategory.speech, 'AssistantProvider: startListening');

    final started = await _speech.startListening(
      onInterimText: (text) {
        _interimText = text;
        notifyListeners();
      },
    );

    if (!started) {
      _setStatus(AssistantStatus.idle);
    }
  }

  /// Stop listening manually.
  Future<void> stopListening() async {
    if (_status != AssistantStatus.listening) return;
    await _speech.stopListening();
    // SpeechFinishedEvent will fire automatically from SpeechService
  }

  /// Process a final transcript through the CommandRouter → TTS pipeline.
  Future<void> _handleTranscript(String transcript) async {
    if (FridayCore.instance.powerMode.isOff) return;

    FridayLogger.log(
      LogCategory.assistant,
      'AssistantProvider: routing "$transcript"',
    );

    // Add user message to transcript
    addMessage(role: 'user', content: transcript);

    // Set processing state
    _setStatus(AssistantStatus.processing);

    // Route through CommandRouter (local-first)
    final result = await FridayCore.instance.route(transcript);

    if (FridayCore.instance.powerMode.isOff) return;

    final response = result?.speechResponse ??
        "I'm sorry, I couldn't process that request.";

    // Add assistant reply to transcript
    addMessage(role: 'assistant', content: response);

    // Fire ActionExecutedEvent for any other subscribers
    EventBus.instance.fire(ActionExecutedEvent(
      moduleId: 'assistant',
      success: result != null,
      speechResponse: response,
    ));

    // Speak the response
    _setStatus(AssistantStatus.speaking);
    await _tts.speak(response);
    // ConversationFinishedEvent fires from TtsService on completion
  }

  // ---------------------------------------------------------------------------
  // Manual speak (for system messages)
  // ---------------------------------------------------------------------------

  /// Speak a message without going through the CommandRouter.
  Future<void> speak(String text) async {
    if (FridayCore.instance.powerMode.isOff) return;
    addMessage(role: 'assistant', content: text);
    _setStatus(AssistantStatus.speaking);
    await _tts.speak(text);
  }

  // ---------------------------------------------------------------------------
  // Transcript management
  // ---------------------------------------------------------------------------

  void addMessage({required String role, required String content}) {
    final msg = AssistantMessage(role: role, content: content);
    _messages.add(msg);
    notifyListeners();
    // Persist in Memory Repository / ChatRepository
    ChatRepository.instance.saveMessage(
      ChatMessage(role: role, content: content),
    );
  }

  void clearMessages() {
    _messages.clear();
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Internal
  // ---------------------------------------------------------------------------

  void _setStatus(AssistantStatus status) {
    if (_status == status) return;
    _status = status;
    notifyListeners();
  }

  @override
  void dispose() {
    for (final sub in _subscriptions) {
      sub.cancel();
    }
    _subscriptions.clear();
    _speech.dispose();
    _tts.dispose();
    super.dispose();
  }
}

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------

/// Current operational status of the assistant voice pipeline.
enum AssistantStatus {
  idle,
  listening,
  processing,
  speaking,
}

/// A single conversation entry.
class AssistantMessage {
  final String role;
  final String content;
  final DateTime timestamp;

  AssistantMessage({
    required this.role,
    required this.content,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}
