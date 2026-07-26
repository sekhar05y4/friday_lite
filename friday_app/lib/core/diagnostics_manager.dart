import 'package:battery_plus/battery_plus.dart';

import '../ai/ai_manager.dart';
import '../repositories/memory_repository.dart';
import '../services/api_service.dart';
import '../services/permission_manager.dart';
import 'background_task_scheduler.dart';
import 'capability_manager.dart';
import 'friday_core.dart';
import 'module_registry.dart';
import 'power_mode.dart';
import '../config/permission_config.dart';

/// Diagnostics report snapshot data structure.
class DiagnosticsReport {
  final bool isPoweredOn;
  final int registeredModuleCount;
  final List<String> moduleNames;
  final String activeAiProvider;
  final bool isBackendOnline;
  final int apiLatencyMs;
  final int batteryLevel;
  final String batteryState;
  final Map<String, dynamic> memorySummary;
  final Map<String, bool> permissionStatus;
  final int activeTaskCount;
  final List<Map<String, dynamic>> activeTasks;
  final DateTime timestamp;

  const DiagnosticsReport({
    required this.isPoweredOn,
    required this.registeredModuleCount,
    required this.moduleNames,
    required this.activeAiProvider,
    required this.isBackendOnline,
    required this.apiLatencyMs,
    required this.batteryLevel,
    required this.batteryState,
    required this.memorySummary,
    required this.permissionStatus,
    required this.activeTaskCount,
    required this.activeTasks,
    required this.timestamp,
  });
}

/// Central Diagnostics Service for FRIDAY.
///
/// Collects comprehensive health metrics across modules, AI provider, SQLite memory,
/// battery level, permissions, and background tasks.
class DiagnosticsManager {
  DiagnosticsManager._();

  static final DiagnosticsManager instance = DiagnosticsManager._();

  final Battery _battery = Battery();

  /// Generate a full system diagnostics report.
  Future<DiagnosticsReport> generateReport() async {
    final isPoweredOn = FridayCore.instance.powerMode.isOn;
    final modules = ModuleRegistry.instance.modules;
    final moduleNames = modules.map((m) => m.moduleId).toList();
    final activeAiProvider = AIManager.instance.active.providerId;

    // API Ping & Latency
    final stopwatch = Stopwatch()..start();
    final isBackendOnline = await ApiService.instance.ping();
    stopwatch.stop();
    final apiLatencyMs = isBackendOnline ? stopwatch.elapsedMilliseconds : -1;

    // Battery
    int batteryLevel = 0;
    String batteryStateStr = 'Unknown';
    try {
      batteryLevel = await _battery.batteryLevel;
      final state = await _battery.batteryState;
      batteryStateStr = state.name;
    } catch (_) {}

    // Memory Summary
    final memorySummary = await MemoryRepository.instance.getMemorySummary();

    // Permissions
    final permissions = [
      PermissionConfig.microphone,
      PermissionConfig.contacts,
      PermissionConfig.phone,
      PermissionConfig.sms,
      PermissionConfig.location,
      PermissionConfig.notification,
    ];

    final Map<String, bool> permStatus = {};
    for (final perm in permissions) {
      permStatus[perm.toString().split('.').last] =
          await PermissionManager.instance.isGranted(perm);
    }

    // Refresh CapabilityManager
    CapabilityManager.instance.refresh();

    return DiagnosticsReport(
      isPoweredOn: isPoweredOn,
      registeredModuleCount: modules.length,
      moduleNames: moduleNames,
      activeAiProvider: activeAiProvider,
      isBackendOnline: isBackendOnline,
      apiLatencyMs: apiLatencyMs,
      batteryLevel: batteryLevel,
      batteryState: batteryStateStr,
      memorySummary: memorySummary,
      permissionStatus: permStatus,
      activeTaskCount: BackgroundTaskScheduler.instance.activeTaskCount,
      activeTasks: BackgroundTaskScheduler.instance.getActiveTaskSummaries(),
      timestamp: DateTime.now(),
    );
  }
}
