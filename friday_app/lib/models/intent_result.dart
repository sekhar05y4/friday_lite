/// Parsed result from the AI intent detection endpoint.
///
/// Returned by [IAIProvider.detectIntent] after the backend analyses the
/// user's speech transcript.
class IntentResult {
  /// The detected intent label (e.g. 'OPEN_APP', 'SEND_SMS', 'CHAT').
  final String intent;

  /// Structured parameters extracted for the intent.
  final Map<String, dynamic> parameters;

  /// The response the TTS engine should speak to the user.
  final String speechResponse;

  /// Confidence score from the AI (0.0 – 1.0).
  final double confidence;

  /// Whether the action requires explicit user confirmation before executing.
  final bool requiresConfirmation;

  const IntentResult({
    required this.intent,
    required this.parameters,
    required this.speechResponse,
    this.confidence = 1.0,
    this.requiresConfirmation = false,
  });

  factory IntentResult.fromMap(Map<String, dynamic> map) => IntentResult(
        intent: map['intent'] as String? ?? 'CHAT',
        parameters:
            (map['parameters'] as Map<String, dynamic>?) ?? {},
        speechResponse: map['speech_response'] as String? ?? '',
        confidence: (map['confidence'] as num?)?.toDouble() ?? 1.0,
        requiresConfirmation:
            map['requires_confirmation'] as bool? ?? false,
      );

  factory IntentResult.chat(String speechResponse) => IntentResult(
        intent: 'CHAT',
        parameters: {},
        speechResponse: speechResponse,
      );
}
