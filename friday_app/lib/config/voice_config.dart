/// Voice / Speech configuration.
/// Tune speech-to-text and text-to-speech behaviour here.
class VoiceConfig {
  VoiceConfig._();

  // --- Speech-to-Text ---
  static const String sttLocale = 'en_US';
  static const int sttListenTimeoutSeconds = 10;
  static const int sttPauseDurationSeconds = 3;

  // --- Text-to-Speech ---
  static const double ttsRate = 0.52;    // 0.0 (slowest) – 1.0 (fastest)
  static const double ttsPitch = 1.05;   // 0.5 (low) – 2.0 (high)
  static const double ttsVolume = 1.0;   // 0.0 – 1.0
  static const String ttsLanguage = 'en-US';

  // --- Wake phrase (display only — not yet active in v1) ---
  static const String wakePhrase = 'friday';

  /// Phrases that trigger power-off from voice.
  static const List<String> sleepPhrases = [
    'friday sleep',
    'go to sleep',
    'stop listening',
    'shut down',
  ];
}
