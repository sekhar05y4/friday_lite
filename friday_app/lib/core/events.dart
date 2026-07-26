/// All typed events used in FRIDAY's in-process Event Bus.
///
/// Modules must never call each other directly.
/// They communicate exclusively by publishing and subscribing to these events.
library friday_events;

// ---------------------------------------------------------------------------
// Power
// ---------------------------------------------------------------------------

class PowerChangedEvent {
  final PowerModeValue mode;
  const PowerChangedEvent(this.mode);
}

enum PowerModeValue { off, on }

// ---------------------------------------------------------------------------
// Speech
// ---------------------------------------------------------------------------

class SpeechStartedEvent {
  const SpeechStartedEvent();
}

class SpeechFinishedEvent {
  final String transcript;
  const SpeechFinishedEvent(this.transcript);
}

class SpeechErrorEvent {
  final String message;
  const SpeechErrorEvent(this.message);
}

// ---------------------------------------------------------------------------
// Conversation
// ---------------------------------------------------------------------------

class ConversationStartedEvent {
  final String userPrompt;
  const ConversationStartedEvent(this.userPrompt);
}

class ConversationFinishedEvent {
  const ConversationFinishedEvent();
}

typedef ConversationCompletedEvent = ConversationFinishedEvent;

// ---------------------------------------------------------------------------
// Module Lifecycle & Commands
// ---------------------------------------------------------------------------

class CommandExecutedEvent {
  final String moduleId;
  final bool success;
  final String speechResponse;
  const CommandExecutedEvent({
    required this.moduleId,
    required this.success,
    required this.speechResponse,
  });
}

typedef ActionExecutedEvent = CommandExecutedEvent;

class ModuleLoadedEvent {
  final String moduleId;
  const ModuleLoadedEvent(this.moduleId);
}

class ModuleUnloadedEvent {
  final String moduleId;
  const ModuleUnloadedEvent(this.moduleId);
}

// ---------------------------------------------------------------------------
// Reminders & Notes
// ---------------------------------------------------------------------------

class ReminderCreatedEvent {
  final String title;
  final DateTime scheduledAt;
  const ReminderCreatedEvent({required this.title, required this.scheduledAt});
}

class ReminderTriggeredEvent {
  final int reminderId;
  final String title;
  const ReminderTriggeredEvent({required this.reminderId, required this.title});
}

class NoteCreatedEvent {
  final String title;
  final String body;
  const NoteCreatedEvent({required this.title, required this.body});
}

// ---------------------------------------------------------------------------
// Telephony & Messaging
// ---------------------------------------------------------------------------

class CallStartedEvent {
  final String recipient;
  const CallStartedEvent(this.recipient);
}

class CallEndedEvent {
  final String recipient;
  const CallEndedEvent(this.recipient);
}

class SMSPreparedEvent {
  final String recipient;
  final String body;
  const SMSPreparedEvent({required this.recipient, required this.body});
}

class SMSDeliveredEvent {
  final String recipient;
  const SMSDeliveredEvent(this.recipient);
}

// ---------------------------------------------------------------------------
// AI Provider Requests
// ---------------------------------------------------------------------------

class AIRequestStartedEvent {
  final String providerId;
  final String prompt;
  const AIRequestStartedEvent({required this.providerId, required this.prompt});
}

class AIResponseReceivedEvent {
  final String providerId;
  final String response;
  final double latencyMs;
  const AIResponseReceivedEvent({
    required this.providerId,
    required this.response,
    required this.latencyMs,
  });
}

// ---------------------------------------------------------------------------
// System Errors & Network
// ---------------------------------------------------------------------------

class ErrorOccurredEvent {
  final String source;
  final String message;
  const ErrorOccurredEvent({required this.source, required this.message});
}

class NetworkStateChangedEvent {
  final bool isConnected;
  final String connectionType;
  const NetworkStateChangedEvent({
    required this.isConnected,
    required this.connectionType,
  });
}

class IntentDetectedEvent {
  final String intent;
  final Map<String, dynamic> parameters;
  final String speechResponse;
  const IntentDetectedEvent({
    required this.intent,
    required this.parameters,
    required this.speechResponse,
  });
}
