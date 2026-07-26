import 'package:permission_handler/permission_handler.dart';

import '../config/permission_config.dart';
import '../utils/logger.dart';

/// Centralised Permission Manager for FRIDAY.
///
/// Ensures no module or component requests Android permissions directly.
/// Every permission request flows through [PermissionManager.instance].
///
/// Supported permission domains:
///   - Microphone ([Permission.microphone])
///   - Contacts ([Permission.contacts])
///   - Phone ([Permission.phone])
///   - SMS ([Permission.sms])
///   - Camera ([Permission.camera])
///   - Notifications ([Permission.notification])
///   - Storage ([Permission.storage] / [Permission.photos])
///   - Bluetooth ([Permission.bluetoothConnect], [Permission.bluetoothScan])
///   - Location ([Permission.location])
class PermissionManager {
  PermissionManager._();

  static final PermissionManager instance = PermissionManager._();

  /// Request [permission] if not already granted.
  ///
  /// Returns `true` if granted after the request.
  /// Returns `false` on denial without throwing raw exceptions.
  /// Automatically redirects to App Settings if permanently denied.
  Future<bool> requestPermission(Permission permission) async {
    final status = await permission.status;

    if (status.isGranted) return true;

    if (status.isPermanentlyDenied) {
      FridayLogger.log(
        LogCategory.assistant,
        'PermissionManager: ${_name(permission)} is permanently denied — redirecting to settings',
      );
      await openAppSettings();
      return false;
    }

    final rationale = PermissionConfig.rationale[permission];
    if (rationale != null) {
      FridayLogger.log(
        LogCategory.assistant,
        'PermissionManager: requesting ${_name(permission)} — rationale: "$rationale"',
      );
    }

    final result = await permission.request();
    FridayLogger.log(
      LogCategory.assistant,
      'PermissionManager: ${_name(permission)} result → ${result.name}',
    );

    return result.isGranted;
  }

  /// Check whether [permission] is currently granted without requesting it.
  Future<bool> isGranted(Permission permission) async {
    return (await permission.status).isGranted;
  }

  // ── Convenience Wrappers ───────────────────────────────────────────────────

  Future<bool> requestMicrophone() => requestPermission(PermissionConfig.microphone);
  Future<bool> requestContacts() => requestPermission(PermissionConfig.contacts);
  Future<bool> requestPhone() => requestPermission(PermissionConfig.phone);
  Future<bool> requestSms() => requestPermission(PermissionConfig.sms);
  Future<bool> requestCamera() => requestPermission(Permission.camera);
  Future<bool> requestNotification() => requestPermission(PermissionConfig.notification);
  Future<bool> requestStorage() => requestPermission(Permission.storage);
  Future<bool> requestLocation() => requestPermission(PermissionConfig.location);

  Future<bool> requestBluetooth() async {
    final scan = await requestPermission(Permission.bluetoothScan);
    final connect = await requestPermission(Permission.bluetoothConnect);
    return scan && connect;
  }

  String _name(Permission permission) => permission.toString();
}
