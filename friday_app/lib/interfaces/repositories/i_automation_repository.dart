abstract class IAutomationRepository {
  Future<List<Map<String, dynamic>>> getRules();
  Future<int> createRule({
    required String name,
    required String triggerType,
    required String conditionJson,
    required String actionCommand,
  });
  Future<bool> toggleRule(int id, bool isEnabled);
  Future<bool> deleteRule(int id);
  Future<void> recordExecution(int ruleId, String ruleName, String resultSpeech);
  Future<List<Map<String, dynamic>>> getExecutionHistory({int limit = 20});
}
