import 'package:flutter/material.dart';

import '../config/theme_config.dart';
import '../models/telemetry_data.dart';
import 'glass_card.dart';

/// Sci-Fi HUD panel displaying connected networks, top active system processes,
/// and live LLM token usage counters.
class HudTokenMeter extends StatelessWidget {
  final TelemetryData data;

  const HudTokenMeter({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final activeNet = data.networks.isNotEmpty ? data.networks.first : 'Wi-Fi';
    final topProcName = data.topApps.isNotEmpty ? data.topApps.first['name'].toString() : 'system';
    final topProcMem = data.topApps.isNotEmpty ? '${data.topApps.first['memory_mb']}MB' : '256MB';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Network & Top Process Status
            Row(
              children: [
                const Icon(Icons.lan_rounded, size: 12, color: ThemeConfig.accent),
                const SizedBox(width: 4),
                Text(
                  activeNet.toUpperCase(),
                  style: const TextStyle(
                    color: ThemeConfig.accent,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '• $topProcName ($topProcMem)',
                  style: const TextStyle(
                    color: ThemeConfig.textMuted,
                    fontSize: 10,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),

            // Token Counter
            Row(
              children: [
                const Icon(Icons.token_rounded, size: 12, color: ThemeConfig.primary),
                const SizedBox(width: 4),
                Text(
                  'TOKENS: ${data.grandTotalTokens}',
                  style: const TextStyle(
                    color: ThemeConfig.primary,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
