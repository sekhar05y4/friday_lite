import 'package:flutter/material.dart';
import '../config/theme_config.dart';
import '../widgets/glass_card.dart';
import 'automation_screen.dart';
import 'camera_vision_screen.dart';
import 'desktop_companion_screen.dart';
import 'diagnostics_screen.dart';
import 'smart_home_screen.dart';

/// Settings screen — Phase 14 full implementation.
/// Includes Developer Diagnostics access.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThemeConfig.background,
      appBar: AppBar(
        title: Text(
          'SETTINGS',
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
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            GlassCard(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.construction_rounded,
                    color: ThemeConfig.primaryDim,
                    size: 40,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Settings',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Full implementation in Phase 14.\nBackend URL, API keys, TTS voice, and more.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            GlassCard(
              child: ListTile(
                leading: const Icon(Icons.camera_enhance_rounded, color: ThemeConfig.accent),
                title: const Text('Camera Vision Platform', style: TextStyle(color: ThemeConfig.textPrimary, fontWeight: FontWeight.bold)),
                subtitle: const Text('QR Scanner, OCR, Face & Object Detection', style: TextStyle(color: ThemeConfig.textSecondary, fontSize: 12)),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, color: ThemeConfig.textMuted, size: 16),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CameraVisionScreen()),
                ),
              ),
            ),
            const SizedBox(height: 12),
            GlassCard(
              child: ListTile(
                leading: const Icon(Icons.desktop_windows_rounded, color: ThemeConfig.primary),
                title: const Text('Desktop Companion', style: TextStyle(color: ThemeConfig.textPrimary, fontWeight: FontWeight.bold)),
                subtitle: const Text('Remote PC screenshot, commands, clipboard, volume & apps', style: TextStyle(color: ThemeConfig.textSecondary, fontSize: 12)),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, color: ThemeConfig.textMuted, size: 16),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const DesktopCompanionScreen()),
                ),
              ),
            ),
            const SizedBox(height: 12),
            GlassCard(
              child: ListTile(
                leading: const Icon(Icons.auto_mode_rounded, color: ThemeConfig.accent),
                title: const Text('Automation Engine', style: TextStyle(color: ThemeConfig.textPrimary, fontWeight: FontWeight.bold)),
                subtitle: const Text('Triggers, conditions, rules & execution logs', style: TextStyle(color: ThemeConfig.textSecondary, fontSize: 12)),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, color: ThemeConfig.textMuted, size: 16),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AutomationScreen()),
                ),
              ),
            ),
            const SizedBox(height: 12),
            GlassCard(
              child: ListTile(
                leading: const Icon(Icons.home_max_rounded, color: ThemeConfig.primary),
                title: const Text('Smart Home Platform', style: TextStyle(color: ThemeConfig.textPrimary, fontWeight: FontWeight.bold)),
                subtitle: const Text('Home Assistant, Google Home, Alexa, Matter, Zigbee, MQTT & BLE', style: TextStyle(color: ThemeConfig.textSecondary, fontSize: 12)),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, color: ThemeConfig.textMuted, size: 16),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SmartHomeScreen()),
                ),
              ),
            ),
            const SizedBox(height: 12),
            GlassCard(
              child: ListTile(
                leading: const Icon(Icons.developer_mode_rounded, color: ThemeConfig.primary),
                title: const Text('Developer Diagnostics', style: TextStyle(color: ThemeConfig.textPrimary, fontWeight: FontWeight.bold)),
                subtitle: const Text('System metrics, latency, memory, plugins & permissions', style: TextStyle(color: ThemeConfig.textSecondary, fontSize: 12)),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, color: ThemeConfig.textMuted, size: 16),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const DiagnosticsScreen()),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
