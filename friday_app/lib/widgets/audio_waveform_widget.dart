import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../providers/assistant_provider.dart';

/// Top-Left Sci-Fi Oscilloscope / ECG Waveform Graph (matching reference UI image).
class AudioWaveformWidget extends StatefulWidget {
  final AssistantStatus status;

  const AudioWaveformWidget({super.key, required this.status});

  @override
  State<AudioWaveformWidget> createState() => _AudioWaveformWidgetState();
}

class _AudioWaveformWidgetState extends State<AudioWaveformWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
          Expanded(
            child: AnimatedBuilder(
              animation: _ctrl,
              builder: (context, _) {
                return CustomPaint(
                  painter: _WaveformPainter(
                    phase: _ctrl.value * 2 * math.pi,
                    status: widget.status,
                  ),
                  child: const SizedBox.expand(),
                );
              },
            ),
          ),
          const SizedBox(height: 4),
          Container(
            height: 1,
            color: const Color(0x6000F0FF),
          ),
        ],
      ),
    );
  }
}

class _WaveformPainter extends CustomPainter {
  final double phase;
  final AssistantStatus status;

  _WaveformPainter({required this.phase, required this.status});

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Background Grid Lines
    final gridPaint = Paint()
      ..color = const Color(0x1A00F0FF)
      ..strokeWidth = 0.8;

    const cols = 8;
    const rows = 4;
    for (int i = 1; i < cols; i++) {
      final x = size.width * (i / cols);
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (int j = 1; j < rows; j++) {
      final y = size.height * (j / rows);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // 2. ECG Oscilloscope Wave Line
    final wavePaint = Paint()
      ..color = const Color(0xFF00F0FF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;

    final glowPaint = Paint()
      ..color = const Color(0x6000F0FF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0;

    final path = Path();
    final midY = size.height / 2;
    final ampMult = status == AssistantStatus.speaking || status == AssistantStatus.listening ? 1.8 : 0.8;

    path.moveTo(0, midY);

    const points = 60;
    for (int i = 0; i <= points; i++) {
      final x = size.width * (i / points);
      final normX = i / points;
      double y = midY;

      // ECG peak simulation in center
      if (normX > 0.35 && normX < 0.65) {
        final spike = math.sin((normX - 0.35) * math.pi / 0.3) * math.sin(phase * 2) * 24 * ampMult;
        y += spike;
      } else {
        y += math.sin(normX * 4 * math.pi + phase) * 4 * ampMult;
      }

      path.lineTo(x, y);
    }

    canvas.drawPath(path, glowPaint);
    canvas.drawPath(path, wavePaint);
  }

  @override
  bool shouldRepaint(_WaveformPainter old) => old.phase != phase || old.status != status;
}
