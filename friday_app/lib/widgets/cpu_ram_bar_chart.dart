import 'package:flutter/material.dart';

import '../models/telemetry_data.dart';

/// Top-Right & Middle-Right Segmented Block Bar Chart Equalizers (matching reference UI image).
class CpuRamBarChart extends StatelessWidget {
  final TelemetryData data;

  const CpuRamBarChart({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final perCpu = data.perCpu.isNotEmpty
        ? data.perCpu
        : [25.0, 40.0, 15.0, 60.0, 30.0, 75.0, 20.0, 50.0];

    return Container(
      padding: const EdgeInsets.all(8),
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
              fontSize: 9,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(height: 6),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(perCpu.length, (i) {
                final load = perCpu[i].clamp(0.0, 100.0);
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
    const totalBlocks = 8;
    final activeBlocks = ((loadPercent / 100) * totalBlocks).round().clamp(1, totalBlocks);

    return Flexible(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 2),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: List.generate(totalBlocks, (idx) {
            final blockIdxFromBottom = totalBlocks - 1 - idx;
            final isActive = blockIdxFromBottom < activeBlocks;
            final isHigh = blockIdxFromBottom >= 6;

            Color blockColor;
            if (!isActive) {
              blockColor = const Color(0x1500F0FF);
            } else if (isHigh) {
              blockColor = const Color(0xFF00FF88);
            } else {
              blockColor = const Color(0xFF00F0FF);
            }

            return Container(
              height: 5,
              margin: const EdgeInsets.symmetric(vertical: 1.5),
              decoration: BoxDecoration(
                color: blockColor,
                borderRadius: BorderRadius.circular(1),
              ),
            );
          }),
        ),
      ),
    );
  }
}
