import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../models/telemetry_data.dart';

/// Bottom-Right 6-Axis Hexagonal Spider Radar Chart (matching reference UI image).
class RadarChartWidget extends StatelessWidget {
  final TelemetryData data;

  const RadarChartWidget({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    // Dynamic values scaled to system metrics
    final cpuNorm = (data.cpuUsage / 100).clamp(0.2, 0.95);
    final ramNorm = (data.ramPercent / 100).clamp(0.3, 0.95);
    final batNorm = (data.batteryPercent / 100).clamp(0.2, 1.0);

    final values = [
      cpuNorm,       // Speed
      ramNorm,       // Power
      0.82,          // Strength
      batNorm,       // Durability
      0.45,          // Weakness
      0.75,          // Tolerance
    ];

    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: const Color(0x1A080E18),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0x4000F0FF), width: 1),
      ),
      child: Stack(
        children: [
          CustomPaint(
            painter: _RadarChartPainter(values: values),
            child: const SizedBox.expand(),
          ),
          const Positioned(
            left: 4,
            top: 2,
            child: Text(
              'SYSTEM MATRIX',
              style: TextStyle(
                color: Color(0xFF00F0FF),
                fontSize: 8.5,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RadarChartPainter extends CustomPainter {
  final List<double> values;
  static const labels = ['Speed', 'Power', 'Strength', 'Durability', 'Weakness', 'Tolerance'];

  _RadarChartPainter({required this.values});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2 + 4);
    final radius = math.min(size.width, size.height) * 0.36;
    const count = 6;

    final gridPaint = Paint()
      ..color = const Color(0x3000F0FF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    // Draw concentric hexagonal grid levels
    for (int level = 1; level <= 3; level++) {
      final r = radius * (level / 3);
      final path = Path();
      for (int i = 0; i < count; i++) {
        final angle = (i * 360 / count - 90) * math.pi / 180;
        final x = center.dx + r * math.cos(angle);
        final y = center.dy + r * math.sin(angle);
        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      path.close();
      canvas.drawPath(path, gridPaint);
    }

    // Draw radial axes & labels
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    for (int i = 0; i < count; i++) {
      final angle = (i * 360 / count - 90) * math.pi / 180;
      final x = center.dx + radius * math.cos(angle);
      final y = center.dy + radius * math.sin(angle);
      canvas.drawLine(center, Offset(x, y), gridPaint);

      // Label text
      final lx = center.dx + (radius + 12) * math.cos(angle);
      final ly = center.dy + (radius + 12) * math.sin(angle);

      textPainter.text = TextSpan(
        text: labels[i],
        style: const TextStyle(
          color: Color(0xCC00F0FF),
          fontSize: 7.5,
          fontFamily: 'monospace',
        ),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(lx - textPainter.width / 2, ly - textPainter.height / 2),
      );
    }

    // Draw filled polygon values
    final polyPath = Path();
    for (int i = 0; i < count; i++) {
      final v = values[i].clamp(0.1, 1.0);
      final r = radius * v;
      final angle = (i * 360 / count - 90) * math.pi / 180;
      final x = center.dx + r * math.cos(angle);
      final y = center.dy + r * math.sin(angle);
      if (i == 0) {
        polyPath.moveTo(x, y);
      } else {
        polyPath.lineTo(x, y);
      }
    }
    polyPath.close();

    final fillPaint = Paint()
      ..color = const Color(0x5500FF88)
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = const Color(0xFF00FF88)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    canvas.drawPath(polyPath, fillPaint);
    canvas.drawPath(polyPath, borderPaint);
  }

  @override
  bool shouldRepaint(_RadarChartPainter old) => old.values != values;
}
