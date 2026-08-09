import 'package:flutter/material.dart';

import '../config/theme_config.dart';
import '../models/telemetry_data.dart';
import 'glass_card.dart';

/// Top Sci-Fi HUD panel displaying real-time system performance metrics
/// (CPU %, RAM GB/%, Battery status, and active system indicator).
class HudTelemetryBar extends StatelessWidget {
  final TelemetryData data;
  final bool isPoweredOn;

  const HudTelemetryBar({
    super.key,
    required this.data,
    required this.isPoweredOn,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        glowColor: isPoweredOn ? ThemeConfig.primary : ThemeConfig.statusOff,
        glowRadius: 10,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            // CPU Badge
            _HudMetricBadge(
              label: 'CPU',
              value: '${data.cpuUsage.toStringAsFixed(1)}%',
              icon: Icons.memory_rounded,
              color: data.cpuUsage > 75 ? Colors.orangeAccent : ThemeConfig.primary,
            ),
            _buildDivider(),

            // RAM Badge
            _HudMetricBadge(
              label: 'RAM',
              value: '${data.ramUsedGb.toStringAsFixed(1)} / ${data.ramTotalGb.toStringAsFixed(0)} GB',
              icon: Icons.pie_chart_outline_rounded,
              color: ThemeConfig.accent,
            ),
            _buildDivider(),

            // Battery Badge
            _HudMetricBadge(
              label: 'PWR',
              value: '${data.batteryPercent}%',
              icon: data.isCharging ? Icons.battery_charging_full_rounded : Icons.battery_std_rounded,
              color: data.batteryPercent < 20 ? Colors.redAccent : ThemeConfig.statusListening,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 20,
      width: 1,
      color: ThemeConfig.border.withValues(alpha: 0.5),
    );
  }
}

class _HudMetricBadge extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _HudMetricBadge({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: ThemeConfig.textMuted,
                fontSize: 9,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.1,
              ),
            ),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace',
              ),
            ),
          ],
        ),
      ],
    );
  }
}
