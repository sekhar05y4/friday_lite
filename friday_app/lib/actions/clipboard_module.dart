import 'package:flutter/services.dart';

import '../core/event_bus.dart';
import '../core/events.dart';
import '../interfaces/i_action_module.dart';
import '../models/command_result.dart';
import '../models/module_capability.dart';
import '../utils/logger.dart';

/// Productivity Action Module for Clipboard Management.
class ClipboardModule implements IActionModule {
  @override
  String get moduleId => 'clipboard';

  @override
  String getDescription() => 'Reads from and writes text to system clipboard.';

  @override
  ModuleCapability get capability => ModuleCapability(
        name: moduleId,
        description: getDescription(),
        supportedCommands: const [
          'clipboard',
          'copy to clipboard',
          'read clipboard',
          'what is on my clipboard',
        ],
      );

  @override
  bool canHandle(String input) {
    final lower = input.toLowerCase().trim();
    return lower.contains('clipboard') ||
        lower.startsWith('copy ') ||
        lower.startsWith('paste');
  }

  @override
  Future<CommandResult> execute(String input, Map<String, dynamic> params) async {
    final lower = input.toLowerCase().trim();

    // ── 1. Copy to clipboard ───────────────────────────────────────────────
    if (lower.startsWith('copy ')) {
      final textToCopy = lower.replaceFirst('copy ', '').trim();
      if (textToCopy.isNotEmpty) {
        await Clipboard.setData(ClipboardData(text: textToCopy));
        FridayLogger.log(LogCategory.action, 'ClipboardModule: copied "$textToCopy"');
        return ActionSuccess(
          speechResponse: 'Copied "$textToCopy" to clipboard.',
          data: {'text': textToCopy},
        );
      }
    }

    // ── 2. Read clipboard ──────────────────────────────────────────────────
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final clipText = data?.text?.trim() ?? '';

    if (clipText.isEmpty) {
      return const ActionSuccess(
        speechResponse: 'Your clipboard is currently empty.',
        data: {'text': ''},
      );
    }

    FridayLogger.log(LogCategory.action, 'ClipboardModule: read "$clipText"');

    EventBus.instance.fire(CommandExecutedEvent(
      moduleId: moduleId,
      success: true,
      speechResponse: 'Clipboard contents: "$clipText".',
    ));

    final display = clipText.length > 50 ? '${clipText.substring(0, 50)}…' : clipText;
    return ActionSuccess(
      speechResponse: 'Clipboard contains: "$display".',
      data: {'text': clipText},
    );
  }

  @override
  void dispose() {}
}
