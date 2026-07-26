import '../core/event_bus.dart';
import '../core/events.dart';
import '../interfaces/i_action_module.dart';
import '../models/command_result.dart';
import '../models/module_capability.dart';
import '../repositories/notes_repository.dart';
import '../utils/logger.dart';

/// Productivity Action Module for Notes & Checklists.
class NotesModule implements IActionModule {
  @override
  String get moduleId => 'notes';

  @override
  String getDescription() => 'Takes voice notes, quick notes, and checklists.';

  @override
  ModuleCapability get capability => ModuleCapability(
        name: moduleId,
        description: getDescription(),
        supportedCommands: const [
          'take note',
          'create note',
          'quick note',
          'checklist',
          'read notes',
          'show notes',
        ],
      );

  @override
  bool canHandle(String input) {
    final lower = input.toLowerCase().trim();
    return lower.startsWith('note') ||
        lower.startsWith('take note') ||
        lower.startsWith('create note') ||
        lower.startsWith('quick note') ||
        lower.startsWith('checklist') ||
        lower.startsWith('read notes') ||
        lower.startsWith('show notes') ||
        lower.startsWith('my notes');
  }

  @override
  Future<CommandResult> execute(String input, Map<String, dynamic> params) async {
    final lower = input.toLowerCase().trim();

    // ── 1. Read / Show Notes ───────────────────────────────────────────────
    if (lower.startsWith('read notes') ||
        lower.startsWith('show notes') ||
        lower == 'my notes') {
      final notes = await NotesRepository.instance.getRecentNotes(limit: 5);

      if (notes.isEmpty) {
        return const ActionSuccess(
          speechResponse: 'You have no saved notes.',
          data: {'count': 0},
        );
      }

      final recent = notes.first.body;
      final speech = 'You have ${notes.length} note${notes.length > 1 ? 's' : ''}. Most recent: "$recent"';
      return ActionSuccess(
        speechResponse: speech,
        data: {'notes': notes.map((n) => n.toMap()).toList()},
      );
    }

    // ── 2. Create Note / Checklist ─────────────────────────────────────────
    final isChecklist = lower.startsWith('checklist');
    final body = lower
        .replaceFirst(RegExp(r'^(take note|create note|quick note|save note|checklist|note)\s*'), '')
        .trim();

    if (body.isEmpty) {
      return const ActionError(
        userFriendlyMessage: 'What would you like me to note down?',
      );
    }

    final title = isChecklist
        ? 'Checklist'
        : body.length > 20
            ? '${body.substring(0, 20)}…'
            : body;

    final id = await NotesRepository.instance.createNote(title, body);

    FridayLogger.log(LogCategory.action, 'NotesModule: saved note #$id "$body"');

    // Publish NoteCreatedEvent to EventBus
    EventBus.instance.fire(NoteCreatedEvent(title: title, body: body));

    final speech = isChecklist ? 'Checklist created: "$body".' : 'Note saved: "$body".';
    return ActionSuccess(
      speechResponse: speech,
      data: {'id': id, 'title': title, 'body': body},
    );
  }

  @override
  void dispose() {}
}
