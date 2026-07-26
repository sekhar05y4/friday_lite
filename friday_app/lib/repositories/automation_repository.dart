import 'package:sqflite/sqflite.dart';

import '../interfaces/repositories/i_automation_repository.dart';
import '../services/database_service.dart';
import '../utils/logger.dart';

/// Repository managing automation rules and execution logs in SQLite.
class AutomationRepository implements IAutomationRepository {
  AutomationRepository._();

  static final AutomationRepository instance = AutomationRepository._();

  static const List<Map<String, String>> _defaultRules = [
    {
      'name': 'Battery Low Protection',
      'trigger_type': 'battery_low',
      'condition_json': '{"threshold": 20}',
      'action_command': 'battery saver',
    },
    {
      'name': 'Headphone Music Launch',
      'trigger_type': 'headphone_connected',
      'condition_json': '{"state": "connected"}',
      'action_command': 'open spotify',
    },
    {
      'name': 'Arriving Home Wi-Fi',
      'trigger_type': 'location_arriving_home',
      'condition_json': '{"geofence": "home"}',
      'action_command': 'open wi-fi settings',
    },
    {
      'name': 'Bedtime Silent Mode',
      'trigger_type': 'time_bedtime',
      'condition_json': '{"time": "22:00"}',
      'action_command': 'silent mode',
    },
  ];

  Future<void> seedDefaultRules() async {
    try {
      final db = await DatabaseService.instance.database;
      final count = Sqflite.firstIntValue(
            await db.rawQuery('SELECT COUNT(*) FROM automation_rules'),
          ) ??
          0;

      if (count == 0) {
        final nowMs = DateTime.now().millisecondsSinceEpoch;
        for (final rule in _defaultRules) {
          await db.insert('automation_rules', {
            'name': rule['name'],
            'trigger_type': rule['trigger_type'],
            'condition_json': rule['condition_json'],
            'action_command': rule['action_command'],
            'is_enabled': 1,
            'created_at': nowMs,
          });
        }
        FridayLogger.log(
          LogCategory.assistant,
          'AutomationRepository: seeded ${_defaultRules.length} default rules',
        );
      }
    } catch (e) {
      FridayLogger.error(LogCategory.assistant, 'AutomationRepository seed error: $e');
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getRules() async {
    await seedDefaultRules();
    try {
      final db = await DatabaseService.instance.database;
      return await db.query('automation_rules', orderBy: 'created_at DESC');
    } catch (e) {
      FridayLogger.error(LogCategory.assistant, 'AutomationRepository getRules error: $e');
      return [];
    }
  }

  @override
  Future<int> createRule({
    required String name,
    required String triggerType,
    required String conditionJson,
    required String actionCommand,
  }) async {
    try {
      final db = await DatabaseService.instance.database;
      final id = await db.insert('automation_rules', {
        'name': name,
        'trigger_type': triggerType,
        'condition_json': conditionJson,
        'action_command': actionCommand,
        'is_enabled': 1,
        'created_at': DateTime.now().millisecondsSinceEpoch,
      });
      FridayLogger.log(LogCategory.assistant, 'AutomationRepository: created rule #$id "$name"');
      return id;
    } catch (e) {
      FridayLogger.error(LogCategory.assistant, 'AutomationRepository createRule error: $e');
      return -1;
    }
  }

  @override
  Future<bool> toggleRule(int id, bool isEnabled) async {
    try {
      final db = await DatabaseService.instance.database;
      final count = await db.update(
        'automation_rules',
        {'is_enabled': isEnabled ? 1 : 0},
        where: 'id = ?',
        whereArgs: [id],
      );
      return count > 0;
    } catch (e) {
      FridayLogger.error(LogCategory.assistant, 'AutomationRepository toggleRule error: $e');
      return false;
    }
  }

  @override
  Future<bool> deleteRule(int id) async {
    try {
      final db = await DatabaseService.instance.database;
      final count = await db.delete('automation_rules', where: 'id = ?', whereArgs: [id]);
      return count > 0;
    } catch (e) {
      FridayLogger.error(LogCategory.assistant, 'AutomationRepository deleteRule error: $e');
      return false;
    }
  }

  @override
  Future<void> recordExecution(int ruleId, String ruleName, String resultSpeech) async {
    try {
      final db = await DatabaseService.instance.database;
      await db.insert('automation_history', {
        'rule_id': ruleId,
        'rule_name': ruleName,
        'triggered_at': DateTime.now().millisecondsSinceEpoch,
        'result_speech': resultSpeech,
      });
      FridayLogger.log(LogCategory.assistant, 'AutomationRepository: recorded execution for "$ruleName"');
    } catch (e) {
      FridayLogger.error(LogCategory.assistant, 'AutomationRepository recordExecution error: $e');
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getExecutionHistory({int limit = 20}) async {
    try {
      final db = await DatabaseService.instance.database;
      return await db.query(
        'automation_history',
        orderBy: 'triggered_at DESC',
        limit: limit,
      );
    } catch (e) {
      FridayLogger.error(LogCategory.assistant, 'AutomationRepository getExecutionHistory error: $e');
      return [];
    }
  }
}
