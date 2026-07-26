import 'package:flutter_tts/flutter_tts.dart';

import '../config/voice_config.dart';
import '../core/event_bus.dart';
import '../core/events.dart';
import '../utils/logger.dart';

/// Wraps the `flutter_tts` package behind a clean, awaitable API.
///
/// Responsibilities:
///   - Initialise TTS with configured language, rate, pitch, and volume.
///   - [speak] awaits completion before returning so callers can chain actions.
///   - Fires [ConversationFinishedEvent] after each utterance completes.
///   - [stop] immediately silences the engine.
///   - [dispose] releases the TTS engine when Power Mode turns OFF.
class TtsService {
  TtsService._();

  static final TtsService instance = TtsService._();

  final FlutterTts _tts = FlutterTts();
  bool _isInitialised = false;
  bool _isSpeaking = false;

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  bool get isSpeaking => _isSpeaking;

  /// Initialise the TTS engine with voice configuration values.
  ///
  /// Safe to call multiple times — subsequent calls are no-ops.
  Future<void> initialize() async {
    if (_isInitialised) return;

    await _tts.setLanguage(VoiceConfig.ttsLanguage);
    await _tts.setSpeechRate(VoiceConfig.ttsRate);
    await _tts.setPitch(VoiceConfig.ttsPitch);
    await _tts.setVolume(VoiceConfig.ttsVolume);

    // Android-specific: queue mode — one utterance at a time
    await _tts.awaitSpeakCompletion(true);

    _tts.setStartHandler(() {
      _isSpeaking = true;
      FridayLogger.log(LogCategory.speech, 'TtsService: started speaking');
    });

    _tts.setCompletionHandler(() {
      _isSpeaking = false;
      FridayLogger.log(LogCategory.speech, 'TtsService: finished speaking');
      EventBus.instance.fire(const ConversationFinishedEvent());
    });

    _tts.setCancelHandler(() {
      _isSpeaking = false;
      FridayLogger.log(LogCategory.speech, 'TtsService: cancelled');
    });

    _tts.setErrorHandler((message) {
      _isSpeaking = false;
      FridayLogger.error(LogCategory.speech, 'TtsService error: $message');
      // Still fire ConversationFinished so the pipeline doesn't stall
      EventBus.instance.fire(const ConversationFinishedEvent());
    });

    _isInitialised = true;
    FridayLogger.log(
      LogCategory.speech,
      'TtsService: initialised '
      '(lang=${VoiceConfig.ttsLanguage}, '
      'rate=${VoiceConfig.ttsRate}, '
      'pitch=${VoiceConfig.ttsPitch})',
    );
  }

  /// Speak [text] and await completion.
  ///
  /// Initialises the engine on first call.
  /// If [text] is empty, fires [ConversationFinishedEvent] immediately.
  Future<void> speak(String text) async {
    if (!_isInitialised) await initialize();

    if (text.trim().isEmpty) {
      EventBus.instance.fire(const ConversationFinishedEvent());
      return;
    }

    FridayLogger.log(LogCategory.speech, 'TtsService: speaking "${_truncate(text)}"');

    // Stop any ongoing speech first
    if (_isSpeaking) await stop();

    _isSpeaking = true;
    await _tts.speak(text);
    // awaitSpeakCompletion(true) ensures we block until done.
    // _completionHandler fires ConversationFinishedEvent.
  }

  /// Immediately stop speaking.
  Future<void> stop() async {
    if (!_isSpeaking && !_isInitialised) return;
    await _tts.stop();
    _isSpeaking = false;
    FridayLogger.log(LogCategory.speech, 'TtsService: stopped');
  }

  /// Update speech rate at runtime (from Settings screen — Phase 14).
  Future<void> setRate(double rate) => _tts.setSpeechRate(rate);

  /// Update pitch at runtime.
  Future<void> setPitch(double pitch) => _tts.setPitch(pitch);

  /// Release TTS engine — call when Power Mode turns OFF.
  Future<void> dispose() async {
    await stop();
    await _tts.stop();
    _isInitialised = false;
    _isSpeaking = false;
    FridayLogger.log(LogCategory.speech, 'TtsService: disposed');
  }

  // ---------------------------------------------------------------------------
  // Internal
  // ---------------------------------------------------------------------------

  String _truncate(String text) =>
      text.length > 60 ? '${text.substring(0, 60)}…' : text;
}
