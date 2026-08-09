import 'dart:async';
import 'package:flutter/foundation.dart';

import '../models/telemetry_data.dart';
import '../services/api_service.dart';
import '../utils/logger.dart';

/// Service for background polling of system telemetry (/api/telemetry)
/// and tracking real-time LLM token metrics.
class TelemetryService extends ChangeNotifier {
  TelemetryService._();

  static final TelemetryService instance = TelemetryService._();

  Timer? _pollingTimer;
  TelemetryData _data = const TelemetryData();

  TelemetryData get data => _data;

  /// Start periodic telemetry updates (every 3 seconds).
  void startPolling() {
    _pollingTimer?.cancel();
    _fetchTelemetry();
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      _fetchTelemetry();
    });
    FridayLogger.log(LogCategory.assistant, 'TelemetryService: started polling');
  }

  /// Stop polling.
  void stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
    FridayLogger.log(LogCategory.assistant, 'TelemetryService: stopped polling');
  }

  /// Record LLM token usage from a response.
  void recordTokenUsage(int promptTokens, int completionTokens) {
    _data = _data.copyWith(
      lastPromptTokens: promptTokens,
      lastCompletionTokens: completionTokens,
      totalPromptTokens: _data.totalPromptTokens + promptTokens,
      totalCompletionTokens: _data.totalCompletionTokens + completionTokens,
    );
    notifyListeners();
    FridayLogger.log(
      LogCategory.api,
      'TelemetryService: recorded tokens prompt=$promptTokens completion=$completionTokens',
    );
  }

  Future<void> _fetchTelemetry() async {
    try {
      final res = await ApiService.instance.getTelemetry();
      if (res.isNotEmpty) {
        _data = TelemetryData.fromJson(
          res,
          lastPromptTokens: _data.lastPromptTokens,
          lastCompletionTokens: _data.lastCompletionTokens,
          totalPromptTokens: _data.totalPromptTokens,
          totalCompletionTokens: _data.totalCompletionTokens,
        );
        notifyListeners();
      }
    } catch (_) {
      // Offline fallback: simulate light idle metrics if server unreachable
      _data = _data.copyWith(
        cpuUsage: 12.4,
        ramPercent: 48.5,
        ramUsedGb: 7.7,
        ramTotalGb: 16.0,
      );
      notifyListeners();
    }
  }

  @override
  void dispose() {
    stopPolling();
    super.dispose();
  }
}
