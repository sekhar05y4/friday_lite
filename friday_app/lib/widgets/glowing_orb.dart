import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../config/animation_config.dart';
import '../providers/assistant_provider.dart';

/// Futuristic Sci-Fi Arc Reactor Core matching the reference infographic UI.
///
/// Features:
///   - Crisp hollow neon-cyan HUD concentric rings
///   - 36-tick outer radial measurement ring
///   - Rotating white and cyan arc segments
///   - Diagonal corner crosshairs
class GlowingOrb extends StatefulWidget {
  final AssistantStatus status;
  final double size;

  const GlowingOrb({
    super.key,
    required this.status,
    this.size = 240,
  });

  @override
  State<GlowingOrb> createState() => _GlowingOrbState();
}

class _GlowingOrbState extends State<GlowingOrb> with TickerProviderStateMixin {
  late AnimationController _breathController;
  late Animation<double> _breathAnim;

  late AnimationController _rotController;
  late Animation<double> _rotAnim;

  late AnimationController _colorController;

  List<Color> _fromColors = const [Color(0xFF00F0FF), Color(0xFF00F0FF), Color(0xFF00FF88)];
  List<Color> _toColors = const [Color(0xFF00F0FF), Color(0xFF00F0FF), Color(0xFF00FF88)];

  @override
  void initState() {
    super.initState();

    _breathController = AnimationController(
      vsync: this,
      duration: _breathDuration(widget.status),
    )..repeat(reverse: true);

    _breathAnim = Tween<double>(begin: 0.94, end: 1.04).animate(
      CurvedAnimation(parent: _breathController, curve: Curves.easeInOut),
    );

    _rotController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();

    _rotAnim = Tween<double>(begin: 0, end: 2 * math.pi).animate(_rotController);

    _colorController = AnimationController(
      vsync: this,
      duration: AnimationConfig.orbTransitionDuration,
    );

    _toColors = _colorsForStatus(widget.status);
    _fromColors = _toColors;
  }

  @override
  void didUpdateWidget(GlowingOrb oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.status != widget.status) {
      final t = _colorController.value;
      _fromColors = List.generate(
        3,
        (i) => Color.lerp(_fromColors[i], _toColors[i], t)!,
      );
      _toColors = _colorsForStatus(widget.status);
      _colorController.forward(from: 0);

      _breathController.duration = _breathDuration(widget.status);
      _breathController
        ..stop()
        ..repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _breathController.dispose();
    _rotController.dispose();
    _colorController.dispose();
    super.dispose();
  }

  List<Color> _colorsForStatus(AssistantStatus s) => switch (s) {
        AssistantStatus.idle => const [Color(0xFF00F0FF), Color(0xFF00F0FF), Color(0xFF00FF88)],
        AssistantStatus.listening => const [Color(0xFF00FF88), Color(0xFF00FF88), Color(0xFF00F0FF)],
        AssistantStatus.processing => const [Color(0xFFE056FD), Color(0xFFE056FD), Color(0xFF00F0FF)],
        AssistantStatus.speaking => const [Color(0xFF2ED573), Color(0xFF2ED573), Color(0xFF00FF88)],
      };

  Duration _breathDuration(AssistantStatus s) => switch (s) {
        AssistantStatus.idle => const Duration(milliseconds: 3000),
        AssistantStatus.listening => const Duration(milliseconds: 900),
        AssistantStatus.processing => const Duration(milliseconds: 500),
        AssistantStatus.speaking => const Duration(milliseconds: 700),
      };

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_breathAnim, _rotAnim, _colorController]),
      builder: (context, _) {
        final t = _colorController.value;
        final colors = List.generate(
          3,
          (i) => Color.lerp(_fromColors[i], _toColors[i], t)!,
        );

        return Transform.scale(
          scale: _breathAnim.value,
          child: SizedBox(
            width: widget.size,
            height: widget.size,
            child: CustomPaint(
              painter: _ArcReactorPainter(
                colors: colors,
                rotation: _rotAnim.value,
                breathValue: _breathAnim.value,
                status: widget.status,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ArcReactorPainter extends CustomPainter {
  final List<Color> colors;
  final double rotation;
  final double breathValue;
  final AssistantStatus status;

  const _ArcReactorPainter({
    required this.colors,
    required this.rotation,
    required this.breathValue,
    required this.status,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final cyanColor = colors[0];
    final accentColor = colors[2];

    // --- 1. Subtle Outer Cyan Glow Aura ---
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          cyanColor.withValues(alpha: 0.18 * breathValue),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, glowPaint);

    // --- 2. Diagonal HUD Corner Crosshair Rays ---
    _drawDiagonalCrosshairs(canvas, center, radius, cyanColor.withValues(alpha: 0.5));

    // --- 3. Outer 36-Tick Measurement Ring ---
    _drawHudTickRing(canvas, center, radius * 0.90, cyanColor.withValues(alpha: 0.6));

    // --- 4. Rotating Outer Segmented White/Cyan Arcs ---
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(-rotation * 0.8);
    canvas.translate(-center.dx, -center.dy);
    _drawArcSegments(canvas, center, radius * 0.82, Colors.white.withValues(alpha: 0.85), strokeWidth: 3.5);
    canvas.restore();

    // --- 5. Rotating Inner Segmented Arcs ---
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotation * 1.2);
    canvas.translate(-center.dx, -center.dy);
    _drawArcSegments(canvas, center, radius * 0.68, cyanColor.withValues(alpha: 0.9), strokeWidth: 3.0);
    canvas.restore();

    // --- 6. Inner Concentric Ring ---
    final innerRingPaint = Paint()
      ..color = cyanColor.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(center, radius * 0.54, innerRingPaint);

    // --- 7. Transparent Core Aura (Hollow - NO DARK SPHERE) ---
    final coreAuraPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          cyanColor.withValues(alpha: 0.35 * breathValue),
          cyanColor.withValues(alpha: 0.05),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius * 0.42));
    canvas.drawCircle(center, radius * 0.42, coreAuraPaint);

    // --- 8. Core Border & Inner Crosshair Target ---
    final borderPaint = Paint()
      ..color = cyanColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawCircle(center, radius * 0.42, borderPaint);

    _drawCenterTargetCrosshair(canvas, center, radius * 0.42, accentColor);

    // --- 9. Sound Wave Rings (Speaking Mode) ---
    if (status == AssistantStatus.speaking) {
      _drawWaveRings(canvas, center, radius, cyanColor);
    }
  }

  void _drawDiagonalCrosshairs(Canvas canvas, Offset center, double radius, Color color) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.0;

    final diag = radius * 0.96;
    final cos45 = math.cos(math.pi / 4) * diag;
    final sin45 = math.sin(math.pi / 4) * diag;

    canvas.drawLine(Offset(center.dx - cos45, center.dy - sin45), Offset(center.dx + cos45, center.dy + sin45), paint);
    canvas.drawLine(Offset(center.dx - cos45, center.dy + sin45), Offset(center.dx + cos45, center.dy - sin45), paint);
  }

  void _drawHudTickRing(Canvas canvas, Offset center, double r, Color color) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    const count = 36;
    for (int i = 0; i < count; i++) {
      final angle = (i * 360 / count) * math.pi / 180;
      final p1 = Offset(center.dx + r * math.cos(angle), center.dy + r * math.sin(angle));
      final p2 = Offset(center.dx + (r - 7) * math.cos(angle), center.dy + (r - 7) * math.sin(angle));
      canvas.drawLine(p1, p2, paint);
    }
  }

  void _drawArcSegments(Canvas canvas, Offset center, double r, Color color, {double strokeWidth = 3.0}) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final rect = Rect.fromCircle(center: center, radius: r);
    canvas.drawArc(rect, 0, math.pi / 3, false, paint);
    canvas.drawArc(rect, 2 * math.pi / 3, math.pi / 3, false, paint);
    canvas.drawArc(rect, 4 * math.pi / 3, math.pi / 3, false, paint);
  }

  void _drawCenterTargetCrosshair(Canvas canvas, Offset center, double r, Color color) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5;

    canvas.drawLine(Offset(center.dx - r * 0.6, center.dy), Offset(center.dx + r * 0.6, center.dy), paint);
    canvas.drawLine(Offset(center.dx, center.dy - r * 0.6), Offset(center.dx, center.dy + r * 0.6), paint);
    canvas.drawCircle(center, 4, Paint()..color = color);
  }

  void _drawWaveRings(Canvas canvas, Offset center, double radius, Color color) {
    for (int i = 1; i <= 3; i++) {
      final ringRadius = radius * (0.45 + i * 0.15);
      final ringPaint = Paint()
        ..color = color.withValues(alpha: (0.35 / i) * breathValue)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      canvas.drawCircle(center, ringRadius, ringPaint);
    }
  }

  @override
  bool shouldRepaint(_ArcReactorPainter old) =>
      old.colors != colors ||
      old.rotation != rotation ||
      old.breathValue != breathValue ||
      old.status != status;
}
