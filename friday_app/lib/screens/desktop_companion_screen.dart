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
  final TextEditingController _hostController = TextEditingController(text: '127.0.0.1');
  final TextEditingController _portController = TextEditingController(text: '8765');
  final TextEditingController _tokenController = TextEditingController(text: 'friday_secret_token_123');
  final TextEditingController _cmdController = TextEditingController();

  bool _isConnected = false;
  bool _isLoading = false;
  String _logOutput = 'Ready to connect to Python Desktop Companion.';

  @override
  void initState() {
    super.initState();
    _isConnected = DesktopCompanionService.instance.isConnected;
  }

  Future<void> _connect() async {
    setState(() => _isLoading = true);
    final host = _hostController.text.trim();
    final port = int.tryParse(_portController.text.trim()) ?? 8765;
    final token = _tokenController.text.trim();

    DesktopCompanionService.instance.configure(host: host, port: port, token: token);
    final ok = await DesktopCompanionService.instance.connect();

    if (mounted) {
      setState(() {
        _isConnected = ok;
        _isLoading = false;
        _logOutput = ok
            ? 'Successfully connected & authenticated with Desktop Companion at $host:$port!'
            : 'Failed to connect to Desktop Companion at $host:$port.';
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
                        decoration: const InputDecoration(labelText: 'Desktop IP / Host', isDense: true),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 1,
                      child: TextField(
                        controller: _portController,
                        style: const TextStyle(color: ThemeConfig.textPrimary, fontSize: 13),
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Port', isDense: true),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _tokenController,
                  obscureText: true,
                  style: const TextStyle(color: ThemeConfig.textPrimary, fontSize: 13),
                  decoration: const InputDecoration(labelText: 'Authentication Token', isDense: true),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _connect,
                    style: ElevatedButton.styleFrom(backgroundColor: ThemeConfig.primary),
                    child: _isLoading
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                        : Text(_isConnected ? 'RECONNECT' : 'CONNECT & AUTHENTICATE', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ── Remote Controls Grid ─────────────────────────────────────────
          const Text(
            'REMOTE DESKTOP ACTIONS',
            style: TextStyle(color: ThemeConfig.textSecondary, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.5),
          ),
          const SizedBox(height: 8),
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            children: [
              _buildActionButton('Screenshot', Icons.screenshot_rounded, () => _executeAction('screenshot', {})),
              _buildActionButton('Sync Clip', Icons.content_copy_rounded, () => _executeAction('clipboard_get', {})),
              _buildActionButton('Battery', Icons.battery_charging_full_rounded, () => _executeAction('battery_status', {})),
              _buildActionButton('Vol Up', Icons.volume_up_rounded, () => _executeAction('volume_control', {'direction': 'up'})),
              _buildActionButton('Vol Down', Icons.volume_down_rounded, () => _executeAction('volume_control', {'direction': 'down'})),
              _buildActionButton('Mute', Icons.volume_off_rounded, () => _executeAction('volume_control', {'direction': 'mute'})),
            ],
          ),

          const SizedBox(height: 16),

          // ── Run Command Input Card ───────────────────────────────────────
          GlassCard(
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _cmdController,
                    style: const TextStyle(color: ThemeConfig.textPrimary, fontSize: 13),
                    decoration: const InputDecoration(hintText: 'Enter desktop terminal command…', isDense: true, border: InputBorder.none),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send_rounded, color: ThemeConfig.primary),
                  onPressed: () {
                    final cmd = _cmdController.text.trim();
                    if (cmd.isNotEmpty) {
                      _executeAction('run_command', {'command': cmd});
                    }
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ── Output Console Log Card ───────────────────────────────────────
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'OUTPUT CONSOLE',
                  style: TextStyle(color: ThemeConfig.primary, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5),
                ),
                const SizedBox(height: 8),
                SelectableText(
                  _logOutput,
                  style: const TextStyle(color: ThemeConfig.textSecondary, fontFamily: 'monospace', fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(String label, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: _isLoading ? null : onTap,
      borderRadius: BorderRadius.circular(16),
      child: GlassCard(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: ThemeConfig.accent, size: 24),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(color: ThemeConfig.textPrimary, fontSize: 11, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
