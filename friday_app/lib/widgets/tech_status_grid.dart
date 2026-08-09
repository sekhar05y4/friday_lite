import 'package:flutter/material.dart';

import '../models/telemetry_data.dart';

/// Middle-Left Tech Status Badges & Radar Scanner Grid (matching reference UI image).
class TechStatusGrid extends StatelessWidget {
  final TelemetryData data;

  const TechStatusGrid({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final netName = data.networks.isNotEmpty ? data.networks.first : 'Wi-Fi';

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
          // 4 Figure Badges
          const Row(
            children: [
              Expanded(child: _BadgeItem(title: 'FIGURE_01 ○', isActive: true)),
              SizedBox(width: 4),
              Expanded(child: _BadgeItem(title: 'FIGURE_03 □', isActive: true)),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(child: _BadgeItem(title: 'FIGURE_02 ✕', isActive: data.isCharging)),
              const SizedBox(width: 4),
              const Expanded(child: _BadgeItem(title: 'FIGURE_04 △', isActive: true)),
            ],
          ),

          const SizedBox(height: 8),

          // Target Scanner Box with concentric circles
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0x1000F0FF),
                border: Border.all(color: const Color(0x3000F0FF), width: 0.8),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Stack(
                children: [
                  CustomPaint(
                    painter: _TargetGridPainter(),
                    child: const SizedBox.expand(),
                  ),
                  Positioned(
                    left: 12,
                    top: 12,
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFF00FF88),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          netName.toUpperCase(),
                          style: const TextStyle(
                            color: Color(0xFF00F0FF),
                            fontSize: 9,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    right: 12,
                    bottom: 12,
                    child: Text(
                      'CPU ${data.cpuUsage.toStringAsFixed(0)}%',
                      style: const TextStyle(
                        color: Color(0xFF00FF88),
                        fontSize: 9,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BadgeItem extends StatelessWidget {
  final String title;
  final bool isActive;

  const _BadgeItem({required this.title, required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: isActive ? const Color(0x2000F0FF) : const Color(0x0A00F0FF),
        border: Border.all(
          color: isActive ? const Color(0xFF00F0FF) : const Color(0x3000F0FF),
          width: 0.8,
        ),
        borderRadius: BorderRadius.circular(2),
      ),
      child: Text(
        title,
        style: TextStyle(
          color: isActive ? const Color(0xFF00F0FF) : const Color(0x6000F0FF),
          fontSize: 8.5,
          fontWeight: FontWeight.bold,
          fontFamily: 'monospace',
        ),
      ),
    );
  }
}

class _TargetGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = const Color(0x1800F0FF)
      ..strokeWidth = 0.8;

    // Grid lines
    for (double x = 0; x < size.width; x += 16) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), linePaint);
    }
    for (double y = 0; y < size.height; y += 16) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
    }

    // Target circles
    final c1 = Offset(size.width * 0.3, size.height * 0.4);
    final c2 = Offset(size.width * 0.7, size.height * 0.7);

    final ringPaint = Paint()
      ..color = const Color(0xFF00FF88)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    canvas.drawCircle(c1, 10, ringPaint);
    canvas.drawCircle(c1, 4, ringPaint);

    canvas.drawCircle(c2, 14, ringPaint..color = const Color(0xFF00F0FF));
    canvas.drawCircle(c2, 6, ringPaint);
  }

  @override
  bool shouldRepaint(_TargetGridPainter old) => false;
}
