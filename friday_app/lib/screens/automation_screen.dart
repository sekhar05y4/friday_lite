import 'package:flutter/material.dart';

import '../config/theme_config.dart';
import '../core/automation_engine.dart';
import '../repositories/automation_repository.dart';
import '../widgets/glass_card.dart';

/// Automation Engine UI Control Panel Screen for FRIDAY.
class AutomationScreen extends StatefulWidget {
  const AutomationScreen({super.key});

  @override
  State<AutomationScreen> createState() => _AutomationScreenState();
}

class _AutomationScreenState extends State<AutomationScreen> {
  List<Map<String, dynamic>> _rules = [];
  List<Map<String, dynamic>> _history = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  Future<void> _refreshData() async {
    setState(() => _isLoading = true);
    final rules = await AutomationRepository.instance.getRules();
    final history = await AutomationRepository.instance.getExecutionHistory();

    if (mounted) {
      setState(() {
        _rules = rules;
        _history = history;
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleRule(int id, bool currentVal) async {
    await AutomationRepository.instance.toggleRule(id, !currentVal);
    await _refreshData();
  }

  Future<void> _runNow() async {
    setState(() => _isLoading = true);
    await AutomationEngine.instance.evaluateAllRules();
    await _refreshData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThemeConfig.background,
      appBar: AppBar(
        title: Text(
          'AUTOMATION ENGINE',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontSize: 14,
                letterSpacing: 4,
                color: ThemeConfig.textPrimary,
              ),
        ),
        centerTitle: true,
        backgroundColor: ThemeConfig.background,
        iconTheme: const IconThemeData(color: ThemeConfig.textSecondary),
        actions: [
          IconButton(
            icon: const Icon(Icons.play_circle_rounded),
            color: ThemeConfig.primary,
            tooltip: 'Run Evaluation Now',
            onPressed: _runNow,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: ThemeConfig.primary))
          : RefreshIndicator(
              onRefresh: _refreshData,
              color: ThemeConfig.primary,
              child: ListView(
                padding: const EdgeInsets.all(16),
                physics: const BouncingScrollPhysics(),
                children: [
                  _buildHeader('AUTOMATION RULES (${_rules.length})', Icons.auto_mode_rounded),
                  const SizedBox(height: 12),
                  ..._rules.map(_buildRuleTile),
                  const SizedBox(height: 24),
                  _buildHeader('EXECUTION LOG (${_history.length})', Icons.history_rounded),
                  const SizedBox(height: 12),
                  if (_history.isEmpty)
                    const Text('No rule executions recorded yet.', style: TextStyle(color: ThemeConfig.textMuted, fontSize: 13))
                  else
                    ..._history.map(_buildHistoryTile),
                ],
              ),
            ),
    );
  }

  Widget _buildHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: ThemeConfig.primary, size: 18),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            color: ThemeConfig.primary,
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildRuleTile(Map<String, dynamic> rule) {
    final id = rule['id'] as int;
    final isEnabled = (rule['is_enabled'] as int) == 1;
    final name = rule['name'] as String;
    final action = rule['action_command'] as String;
    final trigger = rule['trigger_type'] as String;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        child: ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(name, style: const TextStyle(color: ThemeConfig.textPrimary, fontWeight: FontWeight.bold, fontSize: 14)),
          subtitle: Text('Trigger: $trigger → Action: "$action"', style: const TextStyle(color: ThemeConfig.textSecondary, fontSize: 12)),
          trailing: Switch(
            value: isEnabled,
            activeTrackColor: ThemeConfig.primary.withValues(alpha: 0.5),
            onChanged: (val) => _toggleRule(id, isEnabled),
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryTile(Map<String, dynamic> item) {
    final name = item['rule_name'] as String;
    final speech = item['result_speech'] as String;
    final timeMs = item['triggered_at'] as int;
    final date = DateTime.fromMillisecondsSinceEpoch(timeMs);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GlassCard(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.bolt_rounded, color: ThemeConfig.accent, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(color: ThemeConfig.textPrimary, fontWeight: FontWeight.bold, fontSize: 12)),
                  const SizedBox(height: 2),
                  Text(speech, style: const TextStyle(color: ThemeConfig.textSecondary, fontSize: 12)),
                  const SizedBox(height: 2),
                  Text(date.toIso8601String().substring(11, 19), style: const TextStyle(color: ThemeConfig.textMuted, fontSize: 10)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
