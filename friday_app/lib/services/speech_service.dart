import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_recognition_error.dart';

import '../config/voice_config.dart';
import '../core/event_bus.dart';
import '../core/events.dart';
import '../services/permission_service.dart';
import '../utils/logger.dart';

/// Wraps the `speech_to_text` package behind a clean, event-driven API.
class SpeechService {
  SpeechService._();

  static final SpeechService instance = SpeechService._();

  final stt.SpeechToText _stt = stt.SpeechToText();

  bool _isAvailable = false;
  bool _isListening = false;

  void Function(String)? _onInterimText;

  bool get isListening => _isListening;
  bool get isAvailable => _isAvailable;

  Future<bool> initialize() async {
    if (_isAvailable) return true;

    _isAvailable = await _stt.initialize(
      onError: _onError,
      onStatus: _onStatus,
      debugLogging: false,
    );

    FridayLogger.log(
      LogCategory.speech,
      'SpeechService: initialised — available=$_isAvailable',
    );
    return _isAvailable;
  }

  Future<bool> startListening({
    required void Function(String text) onInterimText,
  }) async {
    final hasMic = await PermissionService.instance.requestMicrophone();
    if (!hasMic) {
      FridayLogger.log(
        LogCategory.speech,
        'SpeechService: mic permission denied — cannot start',
      );
      EventBus.instance.fire(const SpeechErrorEvent(
        'Microphone permission is required to listen.',
      ));
      return false;
    }

    if (!_isAvailable) {
      final ok = await initialize();
      if (!ok) {
        EventBus.instance.fire(const SpeechErrorEvent(
          'Speech recognition is not available on this device.',
        ));
        return false;
      }
    }

    if (_isListening) await stopListening();

    _onInterimText = onInterimText;
    _isListening = true;

    FridayLogger.log(LogCategory.speech, 'SpeechService: starting…');

    // ignore: deprecated_member_use
    await _stt.listen(
      onResult: _onResult,
      // ignore: deprecated_member_use
      listenFor: const Duration(seconds: VoiceConfig.sttListenTimeoutSeconds),
      // ignore: deprecated_member_use
      pauseFor: const Duration(seconds: VoiceConfig.sttPauseDurationSeconds),
      // ignore: deprecated_member_use
      localeId: VoiceConfig.sttLocale,
      // ignore: deprecated_member_use
      cancelOnError: false,
      // ignore: deprecated_member_use
      partialResults: true,
    );

    EventBus.instance.fire(const SpeechStartedEvent());
    return true;
  }

  Future<void> stopListening() async {
    if (!_isListening) return;
    _isListening = false;
    await _stt.stop();
    FridayLogger.log(LogCategory.speech, 'SpeechService: stopped (manual)');
    EventBus.instance.fire(const SpeechFinishedEvent(''));
  }

  Future<void> cancel() async {
    if (!_isListening) return;
    _isListening = false;
    await _stt.cancel();
    FridayLogger.log(LogCategory.speech, 'SpeechService: cancelled');
  }

  void dispose() {
    _stt.cancel();
    _isListening = false;
    _isAvailable = false;
    _onInterimText = null;
    FridayLogger.log(LogCategory.speech, 'SpeechService: disposed');
  }

  // ---------------------------------------------------------------------------
  // STT callbacks
  // ---------------------------------------------------------------------------

  void _onResult(SpeechRecognitionResult result) {
    final rawWords = result.recognizedWords.trim();
    final words = _deduplicateWords(rawWords);

    if (!result.finalResult) {
      _onInterimText?.call(words);
      FridayLogger.log(LogCategory.speech, 'STT interim: "$words"');
      return;
    }

    _isListening = false;
    _onInterimText = null;
    FridayLogger.log(LogCategory.speech, 'STT final: "$words"');

    if (words.isEmpty) {
      EventBus.instance.fire(const SpeechFinishedEvent(''));
      return;
    }

    final lower = words.toLowerCase();
    final isSleepPhrase = VoiceConfig.sleepPhrases.any(
      (phrase) => lower.contains(phrase),
    );

    if (isSleepPhrase) {
      FridayLogger.log(
        LogCategory.speech,
        'SpeechService: sleep phrase detected → powering off',
      );
      EventBus.instance.fire(
        const PowerChangedEvent(PowerModeValue.off),
      );
      return;
    }

    EventBus.instance.fire(SpeechFinishedEvent(words));
  }

  /// Deduplicates stuttered or doubled speech tokens from STT engines.
  String _deduplicateWords(String raw) {
    if (raw.trim().isEmpty) return '';
    final tokens = raw.trim().split(RegExp(r'\s+'));
    final List<String> result = [];
    for (final token in tokens) {
      // Remove inline repeating word patterns (e.g. "whatwhatwhat" -> "what")
      final cleanToken = token.replaceAll(RegExp(r'([a-zA-Z]{3,})\1+'), r'$1');
      if (result.isEmpty || result.last.toLowerCase() != cleanToken.toLowerCase()) {
        result.add(cleanToken);
      }
    }
    return result.join(' ');
  }

  void _onError(SpeechRecognitionError error) {
    _isListening = false;
    _onInterimText = null;
    FridayLogger.log(
      LogCategory.speech,
      'SpeechService: error — ${error.errorMsg}',
    );

    if (error.errorMsg == 'error_no_match' ||
        error.errorMsg == 'error_speech_timeout') {
      EventBus.instance.fire(const SpeechFinishedEvent(''));
    } else {
      EventBus.instance.fire(SpeechErrorEvent(
        _friendlyError(error.errorMsg),
      ));
    }
  }

  void _onStatus(String status) {
    FridayLogger.log(LogCategory.speech, 'STT status: $status');
    if (status == 'done' || status == 'notListening') {
      if (_isListening) {
        _isListening = false;
        EventBus.instance.fire(const SpeechFinishedEvent(''));
      }
    }
  }

  String _friendlyError(String raw) {
    if (raw.contains('network')) {
      return 'Speech recognition requires an internet connection.';
    }
    if (raw.contains('permission')) {
      return 'Microphone permission is required.';
    }
    return 'I had trouble hearing you. Please try again.';
  }
}
