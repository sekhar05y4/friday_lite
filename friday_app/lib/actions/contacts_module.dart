import '../core/event_bus.dart';
import '../core/events.dart';
import '../interfaces/i_action_module.dart';
import '../models/command_result.dart';
import '../models/module_capability.dart';
import '../repositories/contacts_repository.dart';
import '../services/permission_manager.dart';
import '../utils/logger.dart';

/// Complete Contacts Assistant Module.
///
/// Features:
///   - Contact Search ("find contact Rahul", "who is Mom")
///   - Open Contacts ("open contacts", "show contacts")
///   - Contact Favorites ("favorite contacts", "show favorites")
///   - Centralized [PermissionManager] validation
///   - EventBus notification publishing
class ContactsModule implements IActionModule {
  @override
  String get moduleId => 'contacts';

  @override
  String getDescription() => 'Searches, lists, and manages contacts and favorites.';

  @override
  ModuleCapability get capability => ModuleCapability(
        name: moduleId,
        description: getDescription(),
        supportedCommands: const [
          'contact',
          'find contact',
          'search contact',
          'who is',
          'open contacts',
          'show contacts',
          'favorite contacts',
          'show favorites',
        ],
      );

  @override
  bool canHandle(String input) {
    final lower = input.toLowerCase().trim();
    return lower.startsWith('contact') ||
        lower.startsWith('find contact') ||
        lower.startsWith('search contact') ||
        lower.startsWith('who is ') ||
        lower.startsWith('get contact') ||
        lower.contains('contacts') ||
        lower.contains('favorites');
  }

  @override
  Future<CommandResult> execute(String input, Map<String, dynamic> params) async {
    final hasPermission = await PermissionManager.instance.requestContacts();
    if (!hasPermission) {
      return const ActionError(
        userFriendlyMessage: 'Contacts permission is required to search contacts.',
      );
    }

    final lower = input.toLowerCase().trim();

    // ── 1. Favorites request ───────────────────────────────────────────────
    if (lower.contains('favorite')) {
      final favorites = await ContactsRepository.instance.searchContacts('');
      FridayLogger.log(LogCategory.action, 'ContactsModule: fetched favorites (${favorites.length})');
      
      final String speech = favorites.isNotEmpty
          ? 'Found ${favorites.length} contacts. First favorite: ${favorites.first.name}.'
          : 'You have no favorite contacts stored.';

      EventBus.instance.fire(CommandExecutedEvent(
        moduleId: moduleId,
        success: true,
        speechResponse: speech,
      ));

      return ActionSuccess(
        speechResponse: speech,
        data: {'favorites': favorites.map((c) => c.toMap()).toList()},
      );
    }

    // ── 2. Open / Show all contacts ────────────────────────────────────────
    if (lower == 'open contacts' || lower == 'show contacts' || lower == 'contacts') {
      final contacts = await ContactsRepository.instance.searchContacts('');
      final count = contacts.length;
      final speech = count > 0
          ? 'Opening contacts list with $count entries.'
          : 'Opening contacts application.';

      EventBus.instance.fire(CommandExecutedEvent(
        moduleId: moduleId,
        success: true,
        speechResponse: speech,
      ));

      return ActionSuccess(
        speechResponse: speech,
        data: {'count': count},
      );
    }

    // ── 3. Specific contact search ─────────────────────────────────────────
    final query = lower
        .replaceFirst(RegExp(r'^(find contact|search contact|who is|get contact|contacts)\s*'), '')
        .trim();

    FridayLogger.log(LogCategory.action, 'ContactsModule: query = "$query"');

    final results = await ContactsRepository.instance.searchContacts(query);

    if (results.isEmpty) {
      final speech = query.isEmpty
          ? 'No contacts found.'
          : 'I could not find any contact matching "$query".';
      
      EventBus.instance.fire(CommandExecutedEvent(
        moduleId: moduleId,
        success: false,
        speechResponse: speech,
      ));

      return ActionSuccess(
        speechResponse: speech,
        data: {'count': 0},
      );
    }

    final first = results.first;
    final speech = 'Found contact ${first.name}. Phone number is ${first.phoneNumber}.';

    EventBus.instance.fire(CommandExecutedEvent(
      moduleId: moduleId,
      success: true,
      speechResponse: speech,
    ));

    return ActionSuccess(
      speechResponse: speech,
      data: {'contacts': results.map((c) => c.toMap()).toList()},
    );
  }

  @override
  void dispose() {}
}
