import '../core/event_bus.dart';
import '../core/events.dart';
import '../interfaces/i_action_module.dart';
import '../models/command_result.dart';
import '../models/module_capability.dart';
import '../repositories/memory_repository.dart';
import '../utils/logger.dart';

/// Long-Term Memory Action Module for FRIDAY.
///
/// Features:
///   - Remember facts, preferences, knowledge, relationships, tasks
///     ("Remember my favorite IDE is VS Code", "Remember I prefer train travel", "Remember office address is Tech Park")
///   - Forget memories ("Forget my favorite IDE", "Forget preference")
///   - Search & Recall memories ("What do you remember about me?", "Search memory")
class MemoryModule implements IActionModule {
  @override
  String get moduleId => 'memory';

  @override
  String getDescription() =>
      'Manages long-term memory, user preferences, knowledge, and recall.';

  @override
  ModuleCapability get capability => ModuleCapability(
        name: moduleId,
        description: getDescription(),
        supportedCommands: const [
          'remember',
          'forget',
          'what do you remember',
          'search memory',
          'my preferences',
        ],
      );

  @override
  bool canHandle(String input) {
    final lower = input.toLowerCase().trim();
    return lower.startsWith('remember') ||
        lower.startsWith('forget ') ||
        lower.contains('what do you remember') ||
        lower.contains('search memory') ||
        lower.contains('my preferences');
  }

  @override
  Future<CommandResult> execute(String input, Map<String, dynamic> params) async {
    final lower = input.toLowerCase().trim();

    // ── 1. Search / Recall Memories ───────────────────────────────────────
    if (lower.contains('what do you remember') ||
        lower.contains('search memory') ||
        lower.contains('my preferences')) {
      final memories = await MemoryRepository.instance.searchMemory('');
      if (memories.isEmpty) {
        return const ActionSuccess(
          speechResponse: 'I currently have no stored long-term memories about you.',
          data: {'count': 0},
        );
      }

      final count = memories.length;
      final firstKey = memories.first['key'] as String;
      final firstVal = memories.first['value'] as String;
      final speech = 'I remember $count item${count > 1 ? 's' : ''}. For example: $firstKey is "$firstVal".';

      return ActionSuccess(
        speechResponse: speech,
        data: {'memories': memories},
      );
    }

    // ── 2. Forget Memory ───────────────────────────────────────────────────
    if (lower.startsWith('forget ')) {
      final keyToForget = lower.replaceFirst('forget ', '').trim();
      if (keyToForget.isEmpty) {
        return const ActionError(
          userFriendlyMessage: 'What information would you like me to forget?',
        );
      }

      final success = await MemoryRepository.instance.forgetMemory(keyToForget);
      final speech = success
          ? 'I have forgotten your preference regarding "$keyToForget".'
          : 'I could not find any stored memory matching "$keyToForget".';

      EventBus.instance.fire(CommandExecutedEvent(
        moduleId: moduleId,
        success: success,
        speechResponse: speech,
      ));

      return ActionSuccess(speechResponse: speech, data: {'key': keyToForget});
    }

    // ── 3. Store / Remember Fact or Preference ─────────────────────────────
    final fact = lower
        .replaceFirst(RegExp(r'^(remember that|remember to|remember)\s*'), '')
        .trim();

    if (fact.isEmpty) {
      return const ActionError(
        userFriendlyMessage: 'What would you like me to remember for you?',
      );
    }

    // Determine memory category
    String memoryType = 'knowledge';
    int ranking = 3;

    if (fact.contains('prefer') || fact.contains('like') || fact.contains('favorite')) {
      memoryType = 'preference';
      ranking = 5;
    } else if (fact.contains('address') || fact.contains('office') || fact.contains('home')) {
      memoryType = 'relationship';
      ranking = 4;
    }

    // Extract key and value
    String key = fact;
    String value = fact;
    if (fact.contains(' is ')) {
      final parts = fact.split(' is ');
      key = parts[0].trim();
      value = parts.sublist(1).join(' is ').trim();
    }

    final id = await MemoryRepository.instance.saveMemory(
      memoryType,
      key,
      value,
      ranking: ranking,
    );

    FridayLogger.log(
      LogCategory.action,
      'MemoryModule: saved $memoryType memory #$id "$key" -> "$value"',
    );

    final speech = 'Got it. I will remember that $key is "$value".';

    EventBus.instance.fire(CommandExecutedEvent(
      moduleId: moduleId,
      success: id > 0,
      speechResponse: speech,
    ));

    return ActionSuccess(
      speechResponse: speech,
      data: {'id': id, 'type': memoryType, 'key': key, 'value': value},
    );
  }

  @override
  void dispose() {}
}
