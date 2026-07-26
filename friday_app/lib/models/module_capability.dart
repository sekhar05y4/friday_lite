import 'package:permission_handler/permission_handler.dart';

/// Metadata descriptor representing a module's capabilities.
///
/// Discovered dynamically by [CapabilityManager].
class ModuleCapability {
  final String name;
  final String description;
  final List<String> supportedCommands;
  final List<Permission> requiredPermissions;
  final String version;

  const ModuleCapability({
    required this.name,
    required this.description,
    this.supportedCommands = const [],
    this.requiredPermissions = const [],
    this.version = '1.0.0',
  });

  Map<String, dynamic> toMap() => {
        'name': name,
        'description': description,
        'supportedCommands': supportedCommands,
        'requiredPermissions':
            requiredPermissions.map((p) => p.toString()).toList(),
        'version': version,
      };
}
