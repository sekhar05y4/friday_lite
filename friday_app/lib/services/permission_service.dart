import 'package:permission_handler/permission_handler.dart';

import 'permission_manager.dart';

/// Legacy facade delegating directly to [PermissionManager].
///
/// Ensures backward compatibility for existing callers. All permission logic
/// resides inside [PermissionManager].
class PermissionService {
  PermissionService._();

  static final PermissionService instance = PermissionService._();

  Future<bool> request(Permission permission) =>
      PermissionManager.instance.requestPermission(permission);

  Future<bool> isGranted(Permission permission) =>
      PermissionManager.instance.isGranted(permission);

  Future<bool> requestMicrophone() =>
      PermissionManager.instance.requestMicrophone();

  Future<bool> requestPhone() => PermissionManager.instance.requestPhone();

  Future<bool> requestSms() => PermissionManager.instance.requestSms();

  Future<bool> requestContacts() => PermissionManager.instance.requestContacts();

  Future<bool> requestLocation() => PermissionManager.instance.requestLocation();

  Future<bool> requestNotification() =>
      PermissionManager.instance.requestNotification();
}
