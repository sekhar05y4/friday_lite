import 'package:flutter/material.dart';

import '../config/theme_config.dart';
import '../models/telemetry_data.dart';
import 'glass_card.dart';

/// Sci-Fi HUD panel displaying real-time Gemini API rate-limit quota metrics:
///   - Tokens (This Request)
///   - TPM (Tokens Per Minute) vs 250,000 limit
///   - RPD (Requests Today) vs 1,500 limit
class HudTokenMeter extends StatelessWidget {
  final TelemetryData data;

  const HudTokenMeter({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Current Request Tokens
            Row(
              children: [
                const Icon(Icons.token_rounded, size: 12, color: ThemeConfig.primary),
                const SizedBox(width: 4),
                Text(
                  'REQ: ${data.lastTotalTokens}',
                  style: const TextStyle(
                    color: ThemeConfig.primary,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),

            // TPM (Tokens Per Minute vs 250k)
            Row(
              children: [
                const Icon(Icons.speed_rounded, size: 12, color: ThemeConfig.accent),
                const SizedBox(width: 4),
                Text(
                  'TPM: ${data.tokensPerMin} / 250K',
                  style: const TextStyle(
                    color: ThemeConfig.accent,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),

            // Requests Today (RPD vs 1,500)
            Row(
              children: [
                const Icon(Icons.today_rounded, size: 12, color: ThemeConfig.statusListening),
                const SizedBox(width: 4),
                Text(
                  'RPD: ${data.requestsToday} / 1.5K',
                  style: const TextStyle(
                    color: ThemeConfig.statusListening,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
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
