import 'dart:math' as math;

import '../interfaces/i_action_module.dart';
import '../models/command_result.dart';
import '../models/module_capability.dart';
import '../utils/logger.dart';

/// Local action module to evaluate basic arithmetic expressions locally.
class CalculatorModule implements IActionModule {
  @override
  String get moduleId => 'calculator';

  @override
  String getDescription() => 'Evaluates mathematical calculations locally.';

  @override
  ModuleCapability get capability => ModuleCapability(
        name: moduleId,
        description: getDescription(),
        supportedCommands: const ['calculate', 'math', 'what is'],
      );

  @override
  bool canHandle(String input) {
    final lower = input.toLowerCase().trim();
    if (lower.startsWith('calculate') ||
        lower.startsWith('math ') ||
        lower.startsWith('what is ') ||
        lower.startsWith('how much is ')) {
      // Check if remainder contains math symbols or numbers
      final expr = lower.replaceAll(RegExp(r'^(calculate|math|what is|how much is)\s+'), '');
      return RegExp(r'[\d+\-*\/%^]').hasMatch(expr);
    }
    return false;
  }

  @override
  Future<CommandResult> execute(String input, Map<String, dynamic> params) async {
    final lower = input.toLowerCase().trim();
    final rawExpr = lower
        .replaceAll(RegExp(r'^(calculate|math|what is|how much is)\s+'), '')
        .replaceAll('plus', '+')
        .replaceAll('minus', '-')
        .replaceAll('times', '*')
        .replaceAll('multiplied by', '*')
        .replaceAll('divided by', '/')
        .replaceAll('over', '/')
        .replaceAll('percent of', '%')
        .trim();

    FridayLogger.log(LogCategory.action, 'CalculatorModule: expr = "$rawExpr"');

    try {
      final double result = _evaluateSimpleExpr(rawExpr);
      final num formatted = result == result.roundToDouble() ? result.toInt() : result;
      return ActionSuccess(
        speechResponse: 'The answer is $formatted.',
        data: {'expression': rawExpr, 'result': formatted},
      );
    } catch (e) {
      FridayLogger.error(LogCategory.action, 'Calculation error for "$rawExpr": $e');
      return ActionError(
        userFriendlyMessage: 'Sorry, I could not evaluate the math expression "$rawExpr".',
      );
    }
  }

  /// Evaluates simple two-operand or basic arithmetic operations safely.
  double _evaluateSimpleExpr(String expr) {
    final clean = expr.replaceAll(' ', '');

    // Square root
    if (clean.startsWith('sqrt') || clean.startsWith('squarerootof')) {
      final numStr = clean.replaceAll(RegExp(r'[^\d.]'), '');
      return math.sqrt(double.parse(numStr));
    }

    // Basic regex operator matching: A op B
    final match = RegExp(r'^([\d.]+)\s*([\+\-\*\/\%\^])\s*([\d.]+)$').firstMatch(clean);
    if (match != null) {
      final a = double.parse(match.group(1)!);
      final op = match.group(2)!;
      final b = double.parse(match.group(3)!);

      switch (op) {
        case '+':
          return a + b;
        case '-':
          return a - b;
        case '*':
          return a * b;
        case '/':
          if (b == 0) throw Exception('Division by zero');
          return a / b;
        case '%':
          return (a * b) / 100.0;
        case '^':
          return math.pow(a, b).toDouble();
      }
    }

    // Try parsing single number
    final single = double.tryParse(clean);
    if (single != null) return single;

    throw Exception('Unsupported expression: $expr');
  }

  @override
  void dispose() {}
}
