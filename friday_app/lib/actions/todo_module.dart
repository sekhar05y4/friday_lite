import '../core/event_bus.dart';
import '../core/events.dart';
import '../interfaces/i_action_module.dart';
import '../models/command_result.dart';
import '../models/module_capability.dart';
import '../repositories/todo_repository.dart';
import '../utils/logger.dart';

/// Productivity Action Module for To-Do Lists & Task Management.
class TodoModule implements IActionModule {
  @override
  String get moduleId => 'todo';

  @override
  String getDescription() => 'Manages to-do lists, pending tasks, and task completion.';

  @override
  ModuleCapability get capability => ModuleCapability(
        name: moduleId,
        description: getDescription(),
        supportedCommands: const [
          'add task',
          'to-do',
          'my tasks',
          'show to-do list',
          'complete task',
        ],
      );

  @override
  bool canHandle(String input) {
    final lower = input.toLowerCase().trim();
    return lower.startsWith('add task') ||
        lower.startsWith('to-do') ||
        lower.startsWith('todo') ||
        lower.startsWith('my tasks') ||
        lower.startsWith('show to-do list') ||
        lower.startsWith('complete task');
  }

  @override
  Future<CommandResult> execute(String input, Map<String, dynamic> params) async {
    final lower = input.toLowerCase().trim();

    // ── 1. Show Tasks ──────────────────────────────────────────────────────
    if (lower == 'my tasks' || lower == 'show to-do list' || lower == 'todo' || lower == 'to-do') {
      final items = await TodoRepository.instance.getTodoItems();
      final pending = items.where((i) => i['is_done'] == 0).toList();

      if (pending.isEmpty) {
        return const ActionSuccess(
          speechResponse: 'You have no pending tasks on your to-do list.',
          data: {'count': 0},
        );
      }

      final firstTask = pending.first['task'] as String;
      final speech = 'You have ${pending.length} pending task${pending.length > 1 ? 's' : ''}. First: "$firstTask".';

      return ActionSuccess(
        speechResponse: speech,
        data: {'tasks': items},
      );
    }

    // ── 2. Complete Task ───────────────────────────────────────────────────
    if (lower.startsWith('complete task')) {
      final taskName = lower.replaceFirst('complete task', '').trim();
      final items = await TodoRepository.instance.getTodoItems();
      final target = items.firstWhere(
        (i) => (i['task'] as String).toLowerCase().contains(taskName),
        orElse: () => {},
      );

      if (target.isNotEmpty) {
        final id = target['id'] as int;
        await TodoRepository.instance.toggleTodoDone(id, true);
        final speech = 'Marked task "${target['task']}" as completed.';

        EventBus.instance.fire(CommandExecutedEvent(
          moduleId: moduleId,
          success: true,
          speechResponse: speech,
        ));

        return ActionSuccess(speechResponse: speech, data: {'id': id});
      }

      return ActionError(userFriendlyMessage: 'Could not find task "$taskName".');
    }

    // ── 3. Add Task ────────────────────────────────────────────────────────
    final task = lower
        .replaceFirst(RegExp(r'^(add task|create task|task)\s*'), '')
        .trim();

    if (task.isEmpty) {
      return const ActionError(
        userFriendlyMessage: 'What task would you like me to add?',
      );
    }

    final id = await TodoRepository.instance.addTodoItem(task);

    FridayLogger.log(LogCategory.action, 'TodoModule: added task #$id "$task"');

    EventBus.instance.fire(CommandExecutedEvent(
      moduleId: moduleId,
      success: id > 0,
      speechResponse: 'Added task: "$task".',
    ));

    final speech = 'Added task: "$task".';
    return ActionSuccess(
      speechResponse: speech,
      data: {'id': id, 'task': task},
    );
  }

  @override
  void dispose() {}
}
