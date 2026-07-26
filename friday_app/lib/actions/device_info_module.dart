import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import '../interfaces/i_action_module.dart';
import '../models/command_result.dart';
import '../models/module_capability.dart';
import '../utils/logger.dart';

/// Local action module to report device info and network status.
class DeviceInfoModule implements IActionModule {
  @override
  String get moduleId => 'device_info';

  @override
  String getDescription() => 'Reports device model, OS version, and network status.';

  @override
  ModuleCapability get capability => ModuleCapability(
        name: moduleId,
        description: getDescription(),
        supportedCommands: const ['device info', 'phone model', 'android version'],
      );

  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();
  final Connectivity _connectivity = Connectivity();

  @override
  bool canHandle(String input) {
    final lower = input.toLowerCase().trim();
    return lower.contains('device info') ||
        lower.contains('phone model') ||
        lower.contains('android version') ||
        lower.contains('system info') ||
        lower.contains('wifi status') ||
        lower.contains('network status');
  }

  @override
  Future<CommandResult> execute(String input, Map<String, dynamic> params) async {
    try {
      String modelStr = 'Device';
      String versionStr = '';

      if (Platform.isAndroid) {
        final info = await _deviceInfo.androidInfo;
        modelStr = '${info.manufacturer} ${info.model}';
        versionStr = 'Android ${info.version.release}';
      }

      final conn = await _connectivity.checkConnectivity();
      final connStr = conn.contains(ConnectivityResult.wifi)
          ? 'Connected to Wi-Fi'
          : conn.contains(ConnectivityResult.mobile)
              ? 'Connected to Mobile Data'
              : 'Offline';

      FridayLogger.log(
        LogCategory.action,
        'DeviceInfoModule: model=$modelStr, version=$versionStr, conn=$connStr',
      );

      return ActionSuccess(
        speechResponse: 'Running on $modelStr ($versionStr). Network: $connStr.',
        data: {
          'model': modelStr,
          'version': versionStr,
          'connectivity': connStr,
        },
      );
    } catch (e) {
      FridayLogger.error(LogCategory.action, 'Failed to fetch device info: $e');
      return const ActionError(
        userFriendlyMessage: 'Could not fetch device details.',
      );
    }
  }

  @override
  void dispose() {}
}
