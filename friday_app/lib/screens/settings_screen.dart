import 'package:flutter/material.dart';

import '../ai/ai_manager.dart';
import '../config/theme_config.dart';
import '../core/automation_engine.dart';
import '../core/capability_manager.dart';
import '../core/friday_core.dart';
import '../repositories/settings_repository.dart';
import '../services/api_service.dart';
import '../widgets/glass_card.dart';
import 'automation_screen.dart';
import 'camera_vision_screen.dart';
import 'desktop_companion_screen.dart';
import 'diagnostics_screen.dart';
import 'smart_home_screen.dart';

/// Settings screen — Comprehensive Settings, App Sync, AI Provider, Backend Config, and All Features Overview.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _urlCtrl = TextEditingController();
  String _activeProvider = 'gemini';
  String _lastRefreshed = '';
  bool _isRefreshing = false;
  String _testResult = '';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final provider = await SettingsRepository.instance.getAiProvider();
    final url = await SettingsRepository.instance.getBackendUrl();
    final lastRef = await SettingsRepository.instance.getString('last_refreshed_timestamp', '');

    if (mounted) {
      setState(() {
        _activeProvider = provider;
        _urlCtrl.text = url;
        _lastRefreshed = lastRef.isNotEmpty ? lastRef : _formattedNow();
      });
    }
  }

  String _formattedNow() {
    final now = DateTime.now();
    final date = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
    final time = "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}";
    return "$date $time";
  }

  Future<void> _refreshAppState() async {
    setState(() {
      _isRefreshing = true;
      _testResult = '';
    });

    final nowStr = _formattedNow();

    // 1. Save settings
    await SettingsRepository.instance.setBackendUrl(_urlCtrl.text.trim());
    await SettingsRepository.instance.setString('last_refreshed_timestamp', nowStr);

    // 2. Refresh capability registry & module discovery
    CapabilityManager.instance.refresh();

    // 3. Trigger Automation Engine evaluation
    await AutomationEngine.instance.evaluateAllRules();

    if (mounted) {
      setState(() {
        _lastRefreshed = nowStr;
        _isRefreshing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('App refreshed & synchronized at $nowStr'),
          backgroundColor: ThemeConfig.statusListening,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _testConnection() async {
    setState(() => _testResult = 'Testing connection…');
    ApiService.instance.setBaseUrl(_urlCtrl.text.trim());
    await SettingsRepository.instance.setBackendUrl(_urlCtrl.text.trim());
    final isOnline = await ApiService.instance.checkHealth();
    if (mounted) {
      setState(() {
        _testResult = isOnline
            ? '✅ Connected to backend successfully!'
            : '⚠️ Backend offline. On-Device Fallback active.';
      });
    }
  }

  void _switchProvider(String providerId) {
    setState(() => _activeProvider = providerId);
    AIManager.instance.setProviderById(providerId);
  }

  @override
  void dispose() {
    _urlCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThemeConfig.background,
      appBar: AppBar(
        title: Text(
          'SETTINGS & FEATURES',
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
            icon: _isRefreshing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: ThemeConfig.primary),
                  )
                : const Icon(Icons.sync_rounded),
            color: ThemeConfig.primary,
            tooltip: 'Sync & Refresh App',
            onPressed: _isRefreshing ? null : _refreshAppState,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        physics: const BouncingScrollPhysics(),
        children: [
          // ── App Sync & Status Banner ─────────────────────────────────────
          GlassCard(
            glowColor: ThemeConfig.primary,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.verified_rounded, color: ThemeConfig.statusListening, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'SYSTEM STATUS: UP TO DATE',
                          style: TextStyle(
                            color: ThemeConfig.statusListening,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                    ElevatedButton.icon(
                      onPressed: _isRefreshing ? null : _refreshAppState,
                      icon: const Icon(Icons.refresh_rounded, size: 14),
                      label: const Text('REFRESH', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ThemeConfig.primary,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  'Last Refreshed: $_lastRefreshed',
                  style: const TextStyle(color: ThemeConfig.textSecondary, fontSize: 12, fontFamily: 'monospace'),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ── AI Provider Selection ─────────────────────────────────────────
          _buildHeader('AI PROVIDER SELECTION', Icons.psychology_rounded),
          const SizedBox(height: 8),
          GlassCard(
            child: Column(
              children: [
                ListTile(
                  leading: Icon(
                    Icons.cloud_rounded,
                    color: _activeProvider == 'gemini' ? ThemeConfig.primary : ThemeConfig.textMuted,
                  ),
                  title: const Text('Gemini AI (Cloud + Fallback)', style: TextStyle(color: ThemeConfig.textPrimary, fontWeight: FontWeight.bold, fontSize: 14)),
                  subtitle: const Text('Connects to Flask Backend / Gemini API with intelligent offline fallback.', style: TextStyle(color: ThemeConfig.textSecondary, fontSize: 12)),
                  trailing: Switch(
                    value: _activeProvider == 'gemini',
                    activeTrackColor: ThemeConfig.primary.withValues(alpha: 0.5),
                    onChanged: (val) => _switchProvider(val ? 'gemini' : 'local_llm'),
                  ),
                ),
                const Divider(color: ThemeConfig.border),
                ListTile(
                  leading: Icon(
                    Icons.cell_wifi_rounded,
                    color: _activeProvider == 'local_llm' ? ThemeConfig.primary : ThemeConfig.textMuted,
                  ),
                  title: const Text('Local LLM (100% Offline)', style: TextStyle(color: ThemeConfig.textPrimary, fontWeight: FontWeight.bold, fontSize: 14)),
                  subtitle: const Text('Connects directly to local Ollama / llama.cpp REST inference server.', style: TextStyle(color: ThemeConfig.textSecondary, fontSize: 12)),
                  trailing: Switch(
                    value: _activeProvider == 'local_llm',
                    activeTrackColor: ThemeConfig.primary.withValues(alpha: 0.5),
                    onChanged: (val) => _switchProvider(val ? 'local_llm' : 'gemini'),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ── Backend Config ───────────────────────────────────────────────
          _buildHeader('BACKEND SERVER CONFIG', Icons.dns_rounded),
          const SizedBox(height: 8),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _urlCtrl,
                  style: const TextStyle(color: ThemeConfig.textPrimary, fontSize: 13),
                  decoration: const InputDecoration(
                    labelText: 'Backend URL',
                    labelStyle: TextStyle(color: ThemeConfig.textSecondary),
                    hintText: 'http://10.0.2.2:5000',
                    hintStyle: TextStyle(color: ThemeConfig.textMuted),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    ElevatedButton(
                      onPressed: _testConnection,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ThemeConfig.surfaceElevated,
                        foregroundColor: ThemeConfig.primary,
                      ),
                      child: const Text('Test Connection'),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _testResult,
                        style: const TextStyle(color: ThemeConfig.textSecondary, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ── All 20 Feature Systems Showcase ──────────────────────────────
          _buildHeader('INTEGRATED FEATURE MODULES (${FridayCore.instance.moduleCount})', Icons.apps_rounded),
          const SizedBox(height: 8),

          _buildFeatureTile(
            title: 'Camera Vision Platform',
            subtitle: 'QR Scanner, OCR, Face & Object Detection',
            icon: Icons.camera_alt_rounded,
            color: ThemeConfig.accent,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CameraVisionScreen())),
          ),
          _buildFeatureTile(
            title: 'Desktop Companion',
            subtitle: 'Remote PC screenshot, commands, clipboard, volume & apps',
            icon: Icons.desktop_windows_rounded,
            color: ThemeConfig.primary,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DesktopCompanionScreen())),
          ),
          _buildFeatureTile(
            title: 'Automation Engine',
            subtitle: 'Triggers, conditions, rules & execution logs',
            icon: Icons.auto_mode_rounded,
            color: ThemeConfig.accent,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AutomationScreen())),
          ),
          _buildFeatureTile(
            title: 'Smart Home Platform',
            subtitle: 'Home Assistant, Google Home, Alexa, Matter, Zigbee, MQTT & BLE',
            icon: Icons.home_max_rounded,
            color: ThemeConfig.primary,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SmartHomeScreen())),
          ),
          _buildFeatureTile(
            title: 'Developer Diagnostics',
            subtitle: 'System metrics, latency, memory, plugins & permissions',
            icon: Icons.developer_mode_rounded,
            color: ThemeConfig.primary,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DiagnosticsScreen())),
          ),

          const SizedBox(height: 12),
          const Text(
            'ADDITIONAL INTEGRATED LOCAL MODULES',
            style: TextStyle(color: ThemeConfig.textMuted, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2),
          ),
          const SizedBox(height: 8),

          _buildModuleSummaryTile('📞 Telephony & SMS Assistant', 'Phone calls, dialer, recent calls, contact resolution, voice confirmation SMS'),
          _buildModuleSummaryTile('📝 Productivity Suite', 'Natural language reminders, voice notes, calendar agenda, alarms, to-do lists, clipboard sync'),
          _buildModuleSummaryTile('⚡ Device Control System', 'Flashlight, Wi-Fi, Bluetooth, Hotspot, Display, Volume, Silent Mode, Airplane Mode'),
          _buildModuleSummaryTile('🚀 Intelligent App Launcher', 'Fuzzy matching app launch, usage stats, recent & favorite apps'),
          _buildModuleSummaryTile('🧠 Long-Term Memory System', 'SQLite memory storage for conversation, preference, knowledge, relationship & task memory'),

          const SizedBox(height: 32),
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

  Widget _buildFeatureTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GlassCard(
        child: ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(icon, color: color),
          title: Text(title, style: const TextStyle(color: ThemeConfig.textPrimary, fontWeight: FontWeight.bold, fontSize: 14)),
          subtitle: Text(subtitle, style: const TextStyle(color: ThemeConfig.textSecondary, fontSize: 12)),
          trailing: const Icon(Icons.arrow_forward_ios_rounded, color: ThemeConfig.textMuted, size: 16),
          onTap: onTap,
        ),
      ),
    );
  }

  Widget _buildModuleSummaryTile(String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GlassCard(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: ThemeConfig.textPrimary, fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 2),
              Text(subtitle, style: const TextStyle(color: ThemeConfig.textSecondary, fontSize: 11)),
            ],
          ),
        ),
      ),
    );
  }
}
