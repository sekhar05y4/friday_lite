import 'package:url_launcher/url_launcher.dart';

import '../core/event_bus.dart';
import '../core/events.dart';
import '../interfaces/i_action_module.dart';
import '../models/command_result.dart';
import '../models/module_capability.dart';
import '../repositories/contacts_repository.dart';
import '../services/permission_manager.dart';
import '../utils/logger.dart';

/// Complete Phone Call Assistant Module.
///
/// Features:
///   - Name resolution via [ContactsRepository] (e.g. "Call Rahul", "Call Mom")
///   - Direct number dialing (e.g. "Dial 9876543210")
///   - Recent call log overview ("Show my recent calls")
///   - EventBus notification publishing ([CallStartedEvent], [CallEndedEvent])
///   - Centralized [PermissionManager] validation
class PhoneCallModule implements IActionModule {
  @override
  String get moduleId => 'phone_call';

  @override
  String getDescription() => 'Initiates phone calls, resolves contact names, and dials numbers.';

  @override
  ModuleCapability get capability => ModuleCapability(
        name: moduleId,
        description: getDescription(),
        supportedCommands: const [
          'call',
          'dial',
          'show my recent calls',
          'recent calls',
        ],
      );

  @override
  bool canHandle(String input) {
    final lower = input.toLowerCase().trim();
    return lower.startsWith('call ') ||
        lower.startsWith('dial ') ||
        lower == 'call' ||
        lower == 'dial' ||
        lower.contains('recent calls');
  }

  @override
  Future<CommandResult> execute(String input, Map<String, dynamic> params) async {
    final lower = input.toLowerCase().trim();

    // ── 1. Recent calls request ────────────────────────────────────────────
    if (lower.contains('recent calls')) {
      FridayLogger.log(LogCategory.action, 'PhoneCallModule: showing recent calls');
      EventBus.instance.fire(const CallEndedEvent('recent_log_viewed'));
      return const ActionSuccess(
        speechResponse: 'Opening call history log.',
        data: {'action': 'recent_calls'},
      );
    }

    // ── 2. Call target extraction ──────────────────────────────────────────
    String target = lower.replaceFirst(RegExp(r'^(call|dial)\s+'), '').trim();

    if (target.isEmpty) {
      return const ActionError(
        userFriendlyMessage: 'Who or what number would you like me to call?',
      );
    }

    final hasPermission = await PermissionManager.instance.requestPhone();
    if (!hasPermission) {
      return const ActionError(
        userFriendlyMessage: 'Phone permission is required to make calls.',
      );
    }

    // Check if target is a contact name or a raw phone number
    final isDigitOnly = RegExp(r'^[\d+\-\s()]+$').hasMatch(target);
    String phoneNumber = target;
    String displayName = target;

    if (!isDigitOnly) {
      final contacts = await ContactsRepository.instance.searchContacts(target);
      if (contacts.isNotEmpty) {
        phoneNumber = contacts.first.phoneNumber;
        displayName = contacts.first.name;
      }
    }

    FridayLogger.log(
      LogCategory.action,
      'PhoneCallModule: calling $displayName ($phoneNumber)',
    );

    // Publish CallStartedEvent to EventBus
    EventBus.instance.fire(CallStartedEvent(displayName));

    final cleanNum = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    final uri = Uri.parse(cleanNum.isNotEmpty ? 'tel:$cleanNum' : 'tel:$phoneNumber');

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
      return ActionSuccess(
        speechResponse: 'Calling $displayName.',
        data: {'target': displayName, 'phone': phoneNumber},
      );
    }

    return ActionError(
      userFriendlyMessage: 'Could not launch dialer for $displayName.',
    );
  }

  @override
  void dispose() {}
}
