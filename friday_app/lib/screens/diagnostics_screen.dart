import 'package:flutter/material.dart';

import '../config/theme_config.dart';
import '../core/diagnostics_manager.dart';
import '../widgets/glass_card.dart';

/// Developer Diagnostics Screen for FRIDAY.
///
/// Displays real-time metrics:
///   - Registered Modules & Plugin Health
///   - AI Provider Status & Backend Latency
///   - Memory & SQLite Record Counts
///   - Battery & Charging State
///   - Runtime Permission Status
///   - Active Background Tasks
class DiagnosticsScreen extends StatefulWidget {
  const DiagnosticsScreen({super.key});

  @override
  State<DiagnosticsScreen> createState() => _DiagnosticsScreenState();
}

class _DiagnosticsScreenState extends State<DiagnosticsScreen> {
  DiagnosticsReport? _report;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _refreshDiagnostics();
  }

  Future<void> _refreshDiagnostics() async {
    setState(() => _isLoading = true);
    final report = await DiagnosticsManager.instance.generateReport();
    if (mounted) {
      setState(() {
        _report = report;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThemeConfig.background,
      appBar: AppBar(
        title: Text(
          'DIAGNOSTICS',
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
            icon: const Icon(Icons.refresh_rounded),
            color: ThemeConfig.primary,
            onPressed: _refreshDiagnostics,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: ThemeConfig.primary),
            )
          : RefreshIndicator(
              onRefresh: _refreshDiagnostics,
              color: ThemeConfig.primary,
              backgroundColor: ThemeConfig.surface,
              child: ListView(
                padding: const EdgeInsets.all(16),
                physics: const BouncingScrollPhysics(),
                children: [
                  _buildSystemCard(_report!),
                  const SizedBox(height: 16),
                  _buildModulesCard(_report!),
                  const SizedBox(height: 16),
                  _buildMemoryCard(_report!),
                  const SizedBox(height: 16),
                  _buildPermissionsCard(_report!),
                  const SizedBox(height: 16),
                  _buildBackgroundTasksCard(_report!),
                ],
              ),
            ),
    );
  }

  Widget _buildSystemCard(DiagnosticsReport report) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader('SYSTEM & AI PROVIDER', Icons.memory_rounded),
          const SizedBox(height: 12),
          _buildRow('Power Mode', report.isPoweredOn ? 'ON' : 'OFF',
              report.isPoweredOn ? ThemeConfig.statusListening : ThemeConfig.statusOff),
          _buildRow('Active AI Provider', report.activeAiProvider.toUpperCase(), ThemeConfig.accent),
          _buildRow(
            'Backend Server',
            report.isBackendOnline ? 'Online (${report.apiLatencyMs} ms)' : 'Offline',
            report.isBackendOnline ? ThemeConfig.statusListening : ThemeConfig.statusOff,
          ),
          _buildRow('Battery', '${report.batteryLevel}% (${report.batteryState})', ThemeConfig.primary),
        ],
      ),
    );
  }

  Widget _buildModulesCard(DiagnosticsReport report) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader('REGISTERED PLUGINS (${report.registeredModuleCount})', Icons.extension_rounded),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: report.moduleNames
                .map((name) => Chip(
                      label: Text(
                        name,
                        style: const TextStyle(fontSize: 11, color: Colors.white),
                      ),
                      backgroundColor: ThemeConfig.primary.withValues(alpha: 0.15),
                      side: BorderSide(color: ThemeConfig.primary.withValues(alpha: 0.4)),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildMemoryCard(DiagnosticsReport report) {
    final mem = report.memorySummary;
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader('MEMORY & SQLITE DATABASE', Icons.storage_rounded),
          const SizedBox(height: 12),
          _buildRow('Chat Messages Persisted', '${mem['chat_messages_count']}'),
          _buildRow('Saved Notes', '${mem['notes_count']}'),
          _buildRow('Pending Reminders', '${mem['reminders_count']}'),
          _buildRow('Stored Contacts', '${mem['contacts_count']}'),
        ],
      ),
    );
  }

  Widget _buildPermissionsCard(DiagnosticsReport report) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader('PERMISSIONS STATUS', Icons.security_rounded),
          const SizedBox(height: 12),
          ...report.permissionStatus.entries.map(
            (e) => _buildRow(
              e.key.toUpperCase(),
              e.value ? 'GRANTED' : 'DENIED',
              e.value ? ThemeConfig.statusListening : ThemeConfig.statusOff,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackgroundTasksCard(DiagnosticsReport report) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader('BACKGROUND TASKS (${report.activeTaskCount})', Icons.schedule_rounded),
          const SizedBox(height: 12),
          if (report.activeTasks.isEmpty)
            const Text(
              'No scheduled background tasks.',
              style: TextStyle(color: ThemeConfig.textMuted, fontSize: 13),
            )
          else
            ...report.activeTasks.map(
              (t) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      t['id'] as String,
                      style: const TextStyle(color: ThemeConfig.textPrimary, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      t['description'] as String,
                      style: const TextStyle(color: ThemeConfig.textSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
        ],
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

  Widget _buildRow(String label, String value, [Color? valueColor]) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: ThemeConfig.textSecondary, fontSize: 13),
          ),
          Text(
            value,
            style: TextStyle(
              color: valueColor ?? ThemeConfig.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
