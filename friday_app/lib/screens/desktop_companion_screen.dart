import 'package:flutter/material.dart';

import '../config/theme_config.dart';
import '../services/desktop_companion_service.dart';
import '../widgets/glass_card.dart';

/// Desktop Companion UI Control Panel Screen for FRIDAY.
class DesktopCompanionScreen extends StatefulWidget {
  const DesktopCompanionScreen({super.key});

  @override
  State<DesktopCompanionScreen> createState() => _DesktopCompanionScreenState();
}

class _DesktopCompanionScreenState extends State<DesktopCompanionScreen> {
  final TextEditingController _hostController = TextEditingController(text: '192.168.1.6');
  final TextEditingController _portController = TextEditingController(text: '5000');
  final TextEditingController _tokenController = TextEditingController(text: 'friday_secret_token_123');

  bool _isConnected = false;
  bool _isLoading = false;
  String _logOutput = 'Ready to connect to Python Desktop Companion.';

  @override
  void initState() {
    super.initState();
    _connect();
  }

  Future<void> _connect() async {
    setState(() => _isLoading = true);
    final host = _hostController.text.trim();
    final port = int.tryParse(_portController.text.trim()) ?? 5000;
    final token = _tokenController.text.trim();

    DesktopCompanionService.instance.configure(host: host, port: port, token: token);
    final ok = await DesktopCompanionService.instance.connect();

    if (mounted) {
      setState(() {
        _isConnected = ok;
        _isLoading = false;
        _logOutput = ok
            ? 'Successfully connected & authenticated with Desktop Companion at $host:$port!'
            : 'Failed to connect to Desktop Companion at $host:$port. Ensure backend is running.';
      });
    }
  }

  Future<void> _executeAction(String action, Map<String, dynamic> payload) async {
    setState(() => _isLoading = true);
    final res = await DesktopCompanionService.instance.sendAction(action, payload);
    if (mounted) {
      setState(() {
        _isLoading = false;
        _logOutput = '[$action] Result:\n${res.toString()}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThemeConfig.background,
      appBar: AppBar(
        title: Text(
          'DESKTOP COMPANION',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontSize: 14,
                letterSpacing: 4,
                color: ThemeConfig.textPrimary,
              ),
        ),
        centerTitle: true,
        backgroundColor: ThemeConfig.background,
        iconTheme: const IconThemeData(color: ThemeConfig.textSecondary),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        physics: const BouncingScrollPhysics(),
        children: [
          // ── Connection Settings Card ─────────────────────────────────────
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'CONNECTION CONFIGURATION',
                      style: TextStyle(color: ThemeConfig.primary, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.5),
                    ),
                    Chip(
                      label: Text(_isConnected ? 'CONNECTED' : 'DISCONNECTED'),
                      backgroundColor: _isConnected
                          ? ThemeConfig.statusListening.withValues(alpha: 0.2)
                          : ThemeConfig.statusOff.withValues(alpha: 0.2),
                      labelStyle: TextStyle(
                        color: _isConnected ? ThemeConfig.statusListening : ThemeConfig.statusOff,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: TextField(
                        controller: _hostController,
                        style: const TextStyle(color: ThemeConfig.textPrimary, fontSize: 13),
                        decoration: const InputDecoration(
                          labelText: 'Desktop IP / Host',
                          labelStyle: TextStyle(color: ThemeConfig.textMuted, fontSize: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 1,
                      child: TextField(
                        controller: _portController,
                        style: const TextStyle(color: ThemeConfig.textPrimary, fontSize: 13),
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Port',
                          labelStyle: TextStyle(color: ThemeConfig.textMuted, fontSize: 12),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _tokenController,
                  obscureText: true,
                  style: const TextStyle(color: ThemeConfig.textPrimary, fontSize: 13),
                  decoration: const InputDecoration(
                    labelText: 'Authentication Token',
                    labelStyle: TextStyle(color: ThemeConfig.textMuted, fontSize: 12),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _connect,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ThemeConfig.accent,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: _isLoading
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                        : const Text('CONNECT & AUTHENTICATE', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Action Buttons ───────────────────────────────────────────────
          const Text(
            'REMOTE DESKTOP ACTIONS',
            style: TextStyle(color: ThemeConfig.textMuted, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5),
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => _executeAction('screenshot', {}),
                  borderRadius: BorderRadius.circular(16),
                  child: const GlassCard(
                    child: Column(
                      children: [
                        Icon(Icons.screenshot_rounded, color: ThemeConfig.accent, size: 28),
                        SizedBox(height: 8),
                        Text('Screenshot', style: TextStyle(color: ThemeConfig.textPrimary, fontSize: 12, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: InkWell(
                  onTap: () => _executeAction('sync_clipboard', {}),
                  borderRadius: BorderRadius.circular(16),
                  child: const GlassCard(
                    child: Column(
                      children: [
                        Icon(Icons.copy_rounded, color: ThemeConfig.accent, size: 28),
                        SizedBox(height: 8),
                        Text('Sync Clip', style: TextStyle(color: ThemeConfig.textPrimary, fontSize: 12, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: InkWell(
                  onTap: () => _executeAction('battery_status', {}),
                  borderRadius: BorderRadius.circular(16),
                  child: const GlassCard(
                    child: Column(
                      children: [
                        Icon(Icons.battery_charging_full_rounded, color: ThemeConfig.accent, size: 28),
                        SizedBox(height: 8),
                        Text('Battery', style: TextStyle(color: ThemeConfig.textPrimary, fontSize: 12, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── Log Console Output ───────────────────────────────────────────
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('LOG OUTPUT', style: TextStyle(color: ThemeConfig.textMuted, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                const SizedBox(height: 8),
                SelectableText(
                  _logOutput,
                  style: const TextStyle(color: ThemeConfig.textSecondary, fontSize: 12, fontFamily: 'monospace'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
