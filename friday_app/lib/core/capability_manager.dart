import 'package:permission_handler/permission_handler.dart';

import '../models/module_capability.dart';
import '../utils/logger.dart';
import 'module_registry.dart';

/// Registry of all installed modules and their capabilities.
///
/// Discovers capabilities dynamically at runtime. Future modules
/// (Camera Vision, OCR, QR Scanner, Smart Home, Local LLM, Desktop Companion)
/// automatically register here without changing FRIDAY Core.
class CapabilityManager {
  CapabilityManager._();

  static final CapabilityManager instance = CapabilityManager._();

  final Map<String, ModuleCapability> _capabilities = {};

  /// Synchronise capabilities from [ModuleRegistry].
  void refresh() {
    _capabilities.clear();
    for (final module in ModuleRegistry.instance.modules) {
      registerCapability(module.capability);
    }
    FridayLogger.log(
      LogCategory.assistant,
      'CapabilityManager: refreshed ${_capabilities.length} module capabilities',
    );
  }

  /// Register a module's capability metadata.
  void registerCapability(ModuleCapability capability) {
    _capabilities[capability.name] = capability;
    FridayLogger.log(
      LogCategory.assistant,
      'CapabilityManager: registered capability "${capability.name}" (v${capability.version})',
    );
  }

  /// Retrieve all registered capabilities.
  List<ModuleCapability> get allCapabilities =>
      List.unmodifiable(_capabilities.values);

  /// Find capability descriptor by module name/ID.
  ModuleCapability? getByName(String name) => _capabilities[name];

  /// Get all permissions required across all active capabilities.
  List<Permission> get allRequiredPermissions {
    final Set<Permission> permissions = {};
    for (final cap in _capabilities.values) {
      permissions.addAll(cap.requiredPermissions);
    }
    return permissions.toList();
  }

  /// Summarise all assistant capabilities into a human-readable prompt string.
  String getCapabilitySummaryPrompt() {
    if (_capabilities.isEmpty) return 'No local modules installed.';
    final buffer = StringBuffer('Installed Assistant Capabilities:\n');
    for (final cap in _capabilities.values) {
      buffer.writeln('- ${cap.name}: ${cap.description}');
    }
    return buffer.toString();
  }
}
