import 'package:flutter/material.dart';

import '../models/telemetry_data.dart';

/// Top-Right Segmented Block Bar Chart Equalizers (matching reference UI image).
class CpuRamBarChart extends StatelessWidget {
  final TelemetryData data;

  const CpuRamBarChart({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final baseCpu = data.cpuUsage > 0 ? data.cpuUsage : 24.0;
    final perCpu = data.perCpu.isNotEmpty
        ? data.perCpu
        : [
            baseCpu * 1.1,
            baseCpu * 1.5,
            baseCpu * 0.8,
            baseCpu * 2.2,
            baseCpu * 1.4,
            baseCpu * 1.8,
            baseCpu * 0.9,
            baseCpu * 2.5,
          ];

    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: const Color(0x1A080E18),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0x4000F0FF), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'SYSTEM LOAD PER CORE',
            style: TextStyle(
              color: Color(0xFF00F0FF),
              fontSize: 8.5,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: List.generate(8, (i) {
                final load = (i < perCpu.length ? perCpu[i] : 30.0).clamp(20.0, 100.0);
                return _SegmentedBar(loadPercent: load);
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class _SegmentedBar extends StatelessWidget {
  final double loadPercent;

  const _SegmentedBar({required this.loadPercent});

  @override
  Widget build(BuildContext context) {
    const totalBlocks = 6;
    final activeBlocks = ((loadPercent / 100) * totalBlocks).round().clamp(2, totalBlocks);

    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 1.5),
        child: Column(
          children: List.generate(totalBlocks, (idx) {
            final blockIdxFromBottom = totalBlocks - 1 - idx;
            final isActive = blockIdxFromBottom < activeBlocks;
            final isHigh = blockIdxFromBottom >= 4;

            Color blockColor;
            if (!isActive) {
              blockColor = const Color(0x2500F0FF);
            } else if (isHigh) {
              blockColor = const Color(0xFF00FF88);
            } else {
              blockColor = const Color(0xFF00F0FF);
            }

            return Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 1.0),
                decoration: BoxDecoration(
                  color: blockColor,
                  borderRadius: BorderRadius.circular(1),
                  boxShadow: isActive
                      ? [
                          BoxShadow(
                            color: blockColor.withValues(alpha: 0.6),
                            blurRadius: 2,
                          ),
                        ]
                      : null,
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
