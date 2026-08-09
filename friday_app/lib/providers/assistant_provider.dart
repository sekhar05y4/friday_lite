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
import '../services/telemetry_service.dart';
import '../services/tts_service.dart';
import '../utils/logger.dart';

/// Represents a single message in the assistant UI transcript log.
class AssistantMessage {
  final String role;
  final String content;
  final DateTime timestamp;

  AssistantMessage({
    required this.role,
    required this.content,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  bool get isUser => role == 'user';
}

enum AssistantStatus {
  idle,
  listening,
  processing,
  speaking,
}

/// Manages the assistant's conversational state and hands-free continuous voice pipeline with wake-word support.
class AssistantProvider extends ChangeNotifier {
  AssistantProvider() {
    _subscribeToEvents();
  }

  final SpeechService _speech = SpeechService.instance;
  final TtsService _tts = TtsService.instance;

  AssistantStatus _status = AssistantStatus.idle;
  String _interimText = '';
  final List<AssistantMessage> _messages = [];
  bool _autoListen = true;
  bool _isStandby = false;

  final List<StreamSubscription<dynamic>> _subscriptions = [];

  AssistantStatus get status => _status;
  String get interimText => _interimText;
  List<AssistantMessage> get messages => List.unmodifiable(_messages);
  bool get isListening => _status == AssistantStatus.listening;
  bool get autoListen => _autoListen;
  bool get isStandby => _isStandby;

  void _setStatus(AssistantStatus status) {
    if (_status == status) return;
    _status = status;
    FridayLogger.log(LogCategory.assistant, 'AssistantStatus → ${status.name}');
    notifyListeners();
  }

  void addMessage({required String role, required String content}) {
    _messages.add(AssistantMessage(role: role, content: content));
    notifyListeners();
    ChatRepository.instance.saveMessage(ChatMessage(role: role, content: content));
  }

  void _subscribeToEvents() {
    _subscriptions.add(
      EventBus.instance.on<PowerChangedEvent>().listen((event) {
        if (event.mode == PowerModeValue.off) {
          _handlePowerOff();
        } else {
          _handlePowerOn();
        }
      }),
    );

    _subscriptions.add(
      EventBus.instance.on<SpeechStartedEvent>().listen((_) {
        _setStatus(AssistantStatus.listening);
      }),
    );

    _subscriptions.add(
      EventBus.instance.on<SpeechFinishedEvent>().listen((event) {
        _interimText = '';
        notifyListeners();
        if (event.transcript.isNotEmpty) {
          _handleTranscript(event.transcript);
        } else {
          _setStatus(AssistantStatus.idle);
          _scheduleAutoReListen();
        }
      }),
    );

    _subscriptions.add(
      EventBus.instance.on<SpeechErrorEvent>().listen((event) {
        _interimText = '';
        _setStatus(AssistantStatus.idle);
        _scheduleAutoReListen();
      }),
    );

    _subscriptions.add(
      EventBus.instance.on<ConversationFinishedEvent>().listen((_) {
        if (FridayCore.instance.powerMode.isOff) return;
        _setStatus(AssistantStatus.idle);
        _scheduleAutoReListen();
      }),
    );
  }

  void _scheduleAutoReListen() {
    if (_autoListen && FridayCore.instance.powerMode.isOn) {
      Future.delayed(const Duration(milliseconds: 200), () {
        if (FridayCore.instance.powerMode.isOn) {
          startListening();
        }
      });
    }
  }

  bool _isBriefingInProgress = false;

  void _handlePowerOn() {
    _autoListen = true;
    _isStandby = false;
    startListening();
  }

  void _handlePowerOff() {
    _speech.stopListening();
    _tts.stop();
    _status = AssistantStatus.idle;
    _interimText = '';
    _isBriefingInProgress = false;
    notifyListeners();
  }

  /// Automated "Wake Up FRIDAY" Voice Briefing Routine
  Future<void> triggerWakeUpBriefing() async {
    if (FridayCore.instance.powerMode.isOff) return;
    if (_isBriefingInProgress) return;
    _isBriefingInProgress = true;

    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? "Good morning, Boss."
        : (hour < 17 ? "Good afternoon, Boss." : "Good evening, Boss.");

    final telemetry = TelemetryService.instance.data;
    final cpu = telemetry.cpuUsage.toStringAsFixed(0);
    final ramUsed = telemetry.ramUsedGb.toStringAsFixed(1);
    final ramTotal = telemetry.ramTotalGb.toStringAsFixed(0);
    final bat = telemetry.batteryPercent;
    final chargingStr = telemetry.isCharging ? "charging" : "discharging";
    final topApp = telemetry.topApps.isNotEmpty ? telemetry.topApps.first['name'].toString() : 'System';
    final net = telemetry.networks.isNotEmpty ? telemetry.networks.first : 'Wi-Fi';

    final briefingText = "$greeting All systems operational. CPU load is at $cpu percent. RAM usage is $ramUsed out of $ramTotal gigabytes. Battery is at $bat percent and $chargingStr. Active processes include $topApp. Connection verified on $net.";

    _autoListen = true;
    _isStandby = false;
    await speak(briefingText);
    _isBriefingInProgress = false;
  }

  Future<void> startListening() async {
    if (FridayCore.instance.powerMode.isOff) return;
    if (_status == AssistantStatus.listening) return;

    final started = await _speech.startListening(
      onInterimText: (text) {
        _interimText = text;
        notifyListeners();
      },
    );

    if (!started) {
      _setStatus(AssistantStatus.idle);
      _scheduleAutoReListen();
    }
  }

  Future<void> stopListening() async {
    _autoListen = false;
    if (_status == AssistantStatus.listening) {
      await _speech.stopListening();
    }
    _setStatus(AssistantStatus.idle);
  }

  Future<void> processTextInput(String text) async {
    if (text.trim().isEmpty) return;
    await _handleTranscript(text.trim());
  }

  Future<void> _handleTranscript(String transcript) async {
    if (FridayCore.instance.powerMode.isOff) return;

    final lower = transcript.toLowerCase().trim();

    // ── Check Wake Words ───────────────────────────────────────────────────
    final isWakeWord = lower.contains('wake up friday') ||
        lower.contains('hey friday') ||
        lower.contains('ok friday') ||
        lower.contains('wake up') ||
        lower == 'friday';

    if (_isStandby) {
      if (isWakeWord) {
        _isStandby = false;
        notifyListeners();
        addMessage(role: 'user', content: transcript);
        await triggerWakeUpBriefing();
      } else {
        // Silently ignore speech while in Standby mode, keeping mic active!
        _scheduleAutoReListen();
      }
      return;
    }

    // ── Check Sleep Words ──────────────────────────────────────────────────
    final isSleepWord = lower.contains('go to sleep') ||
        lower.contains('sleep friday') ||
        lower.contains('standby friday') ||
        lower == 'sleep' ||
        lower == 'go sleep';

    if (isSleepWord) {
      _isStandby = true;
      notifyListeners();
      addMessage(role: 'user', content: transcript);
      await speak("Entering standby mode. I am listening for your wake word.");
      return;
    }

    if (isWakeWord) {
      addMessage(role: 'user', content: transcript);
      await triggerWakeUpBriefing();
      return;
    }

    // ── Normal Active Command Execution ────────────────────────────────────
    addMessage(role: 'user', content: transcript);
    _setStatus(AssistantStatus.processing);

    final result = await FridayCore.instance.route(transcript);

    if (FridayCore.instance.powerMode.isOff) return;

    final response = result?.speechResponse ?? "I'm sorry, I couldn't process that request.";

    addMessage(role: 'assistant', content: response);

    EventBus.instance.fire(ActionExecutedEvent(
      moduleId: 'assistant',
      success: result != null,
      speechResponse: response,
    ));

    _setStatus(AssistantStatus.speaking);
    await _tts.speak(response);
  }

  Future<void> speak(String text) async {
    if (FridayCore.instance.powerMode.isOff) return;
    addMessage(role: 'assistant', content: text);
    _setStatus(AssistantStatus.speaking);
    await _tts.speak(text);
  }

  @override
  void dispose() {
    for (final s in _subscriptions) {
      s.cancel();
    }
    super.dispose();
  }
}
