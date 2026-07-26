import 'package:permission_handler/permission_handler.dart';

/// Groups of permissions required for each feature.
/// Permissions are requested lazily — only when the feature is first used.
class PermissionConfig {
  PermissionConfig._();

  static const Permission microphone = Permission.microphone;
  static const Permission phone = Permission.phone;
  static const Permission sms = Permission.sms;
  static const Permission contacts = Permission.contacts;
  static const Permission location = Permission.locationWhenInUse;
  static const Permission notification = Permission.notification;

  /// Human-readable reasons shown in rationale dialogs.
  /// Not const — Permission overrides == and hashCode.
  static Map<Permission, String> get rationale => {
    Permission.microphone:
        'Microphone access is needed to hear your voice commands.',
    Permission.phone:
        'Phone permission is needed to make calls on your behalf.',
    Permission.sms:
        'SMS permission is needed to send messages on your behalf.',
    Permission.contacts:
        'Contacts permission is needed to look up names for calls and messages.',
    Permission.locationWhenInUse:
        'Location is used to provide accurate weather for your area.',
    Permission.notification:
        'Notification permission is needed to deliver reminder alerts.',
  };
}
