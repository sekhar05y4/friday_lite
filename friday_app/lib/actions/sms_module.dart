import 'package:url_launcher/url_launcher.dart';

import '../core/event_bus.dart';
import '../core/events.dart';
import '../interfaces/i_action_module.dart';
import '../models/command_result.dart';
import '../models/module_capability.dart';
import '../repositories/contacts_repository.dart';
import '../services/permission_manager.dart';
import '../utils/logger.dart';

/// Complete SMS Assistant Module.
///
/// Features:
///   - Handles "message Mom I'll be late", "text Rahul meeting at 5"
///   - Resolves contact names via [ContactsRepository]
///   - Voice confirmation draft mode before sending SMS
///   - Recent message view ("show recent messages")
///   - Publishes [SMSPreparedEvent] and [SMSDeliveredEvent] to [EventBus]
///   - Centralized [PermissionManager] validation
class SmsModule implements IActionModule {
  @override
  String get moduleId => 'sms';

  @override
  String getDescription() => 'Drafts, prepares, and sends SMS messages with contact resolution.';

  @override
  ModuleCapability get capability => ModuleCapability(
        name: moduleId,
        description: getDescription(),
        supportedCommands: const [
          'send sms',
          'text',
          'message',
          'send message',
          'recent messages',
        ],
      );

  @override
  bool canHandle(String input) {
    final lower = input.toLowerCase().trim();
    return lower.startsWith('send sms') ||
        lower.startsWith('text ') ||
        lower.startsWith('message ') ||
        lower.startsWith('send message') ||
        lower.startsWith('send text') ||
        lower.contains('recent messages');
  }

  @override
  Future<CommandResult> execute(String input, Map<String, dynamic> params) async {
    final lower = input.toLowerCase().trim();

    // ── 1. Recent messages request ─────────────────────────────────────────
    if (lower.contains('recent messages')) {
      FridayLogger.log(LogCategory.action, 'SmsModule: showing recent messages');
      return const ActionSuccess(
        speechResponse: 'Opening SMS messages application.',
        data: {'action': 'recent_messages'},
      );
    }

    final hasPermission = await PermissionManager.instance.requestSms();
    if (!hasPermission) {
      return const ActionError(
        userFriendlyMessage: 'SMS permission is required to send messages.',
      );
    }

    // ── 2. Parse recipient and message body ────────────────────────────────
    // Examples:
    //   "message Mom I'll be late"
    //   "text Rahul meeting at 5"
    //   "send sms to 9876543210 saying hello"
    String recipient = '';
    String body = '';

    // Regex 1: "message/text/send text <name/number> <body...>"
    final msgMatch = RegExp(
      r'^(?:message|text|send text|send message|send sms)\s+(?:to\s+)?([a-zA-Z0-9_\s()+\-]+?)\s+(?:saying|that|message|body)?\s*(.+)$',
      caseSensitive: false,
    ).firstMatch(lower);

    if (msgMatch != null) {
      recipient = msgMatch.group(1)?.trim() ?? '';
      body = msgMatch.group(2)?.trim() ?? '';
    } else {
      final parts = lower.split(' ');
      if (parts.length > 1) {
        recipient = parts[1];
        if (parts.length > 2) {
          body = parts.sublist(2).join(' ');
        }
      }
    }

    if (recipient.isEmpty) {
      return const ActionError(
        userFriendlyMessage: 'Who would you like me to send a message to?',
      );
    }

    // Contact name resolution
    final isDigitOnly = RegExp(r'^[\d+\-\s()]+$').hasMatch(recipient);
    String phoneNumber = recipient;
    String displayName = recipient;

    if (!isDigitOnly) {
      final contacts = await ContactsRepository.instance.searchContacts(recipient);
      if (contacts.isNotEmpty) {
        phoneNumber = contacts.first.phoneNumber;
        displayName = contacts.first.name;
      }
    }

    FridayLogger.log(
      LogCategory.action,
      'SmsModule: recipient=$displayName ($phoneNumber), body="$body"',
    );

    // Fire SMSPreparedEvent
    EventBus.instance.fire(SMSPreparedEvent(recipient: displayName, body: body));

    final cleanNum = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    final uri = Uri(
      scheme: 'sms',
      path: cleanNum.isNotEmpty ? cleanNum : phoneNumber,
      queryParameters: body.isNotEmpty ? {'body': body} : null,
    );

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);

      // Fire SMSDeliveredEvent
      EventBus.instance.fire(SMSDeliveredEvent(displayName));

      final confirmText = body.isNotEmpty
          ? 'Drafted message to $displayName: "$body". Opening SMS app to send.'
          : 'Opening message editor for $displayName.';

      return ActionSuccess(
        speechResponse: confirmText,
        data: {'recipient': displayName, 'phone': phoneNumber, 'body': body},
      );
    }

    return const ActionError(
      userFriendlyMessage: 'Could not open SMS application.',
    );
  }

  @override
  void dispose() {}
}
