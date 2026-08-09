import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../config/animation_config.dart';
import '../config/theme_config.dart';
import '../providers/assistant_provider.dart';

/// Futuristic Jarvis-Style Arc Reactor Core.
///
/// Features:
///   - Concentric HUD tech rings with tick marks
///   - Clockwise & counter-clockwise rotating energy arcs
///   - Reactive multi-layered glow aura (Cyan, Gold, Purple, Green)
///   - Crisp Sci-Fi central reactor core
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

class _GlowingOrbState extends State<GlowingOrb>
    with TickerProviderStateMixin {
  late AnimationController _breathController;
  late Animation<double> _breathAnim;

  late AnimationController _rotController;
  late Animation<double> _rotAnim;

  late AnimationController _colorController;

  List<Color> _fromColors = ThemeConfig.orbOff;
  List<Color> _toColors = ThemeConfig.orbOff;

  @override
  void initState() {
    super.initState();

    _breathController = AnimationController(
      vsync: this,
      duration: _breathDuration(widget.status),
    )..repeat(reverse: true);

    _breathAnim = Tween<double>(begin: 0.90, end: 1.05).animate(
      CurvedAnimation(parent: _breathController, curve: Curves.easeInOut),
    );

    _rotController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
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
        AssistantStatus.idle => ThemeConfig.orbOff,
        AssistantStatus.listening => ThemeConfig.orbListening,
        AssistantStatus.processing => ThemeConfig.orbProcessing,
        AssistantStatus.speaking => ThemeConfig.orbSpeaking,
      };

  Duration _breathDuration(AssistantStatus s) => switch (s) {
        AssistantStatus.idle => const Duration(milliseconds: 3000),
        AssistantStatus.listening => const Duration(milliseconds: 800),
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

    // --- 1. Outer Glow Aura ---
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          colors[1].withValues(alpha: 0.22 * breathValue),
          colors[0].withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, glowPaint);

    // --- 2. Outer HUD Tick Ring ---
    _drawHudTickRing(canvas, center, radius * 0.92, colors[1].withValues(alpha: 0.4));

    // --- 3. Rotating Outer Arc Segments ---
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(-rotation * 0.8);
    canvas.translate(-center.dx, -center.dy);
    _drawArcSegments(canvas, center, radius * 0.82, colors[1].withValues(alpha: 0.7));
    canvas.restore();

    // --- 4. Rotating Inner Arc Segments ---
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotation * 1.2);
    canvas.translate(-center.dx, -center.dy);
    _drawArcSegments(canvas, center, radius * 0.68, colors[2].withValues(alpha: 0.8));
    canvas.restore();

    // --- 5. Inner Concentric Ring ---
    final innerRingPaint = Paint()
      ..color = colors[1].withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(center, radius * 0.58, innerRingPaint);

    // --- 6. Core Reactor Orb ---
    final corePaint = Paint()
      ..shader = RadialGradient(
        colors: [
          colors[1].withValues(alpha: 0.95),
          colors[0].withValues(alpha: 0.85),
          colors[2].withValues(alpha: 0.7),
        ],
        stops: const [0.0, 0.45, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius * 0.46));
    canvas.drawCircle(center, radius * 0.46, corePaint);

    // --- 7. Core Highlight ---
    final highlightPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.35, -0.35),
        colors: [
          Colors.white.withValues(alpha: 0.35),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius * 0.46));
    canvas.drawCircle(center, radius * 0.46, highlightPaint);

    // --- 8. Core Border & Tri-Arc Crosshairs ---
    final borderPaint = Paint()
      ..color = colors[1].withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawCircle(center, radius * 0.46, borderPaint);

    _drawCrosshairs(canvas, center, radius * 0.46, colors[1]);

    // --- 9. Sound Wave Waves (Speaking Mode) ---
    if (status == AssistantStatus.speaking) {
      _drawWaveRings(canvas, center, radius, colors[1]);
    }
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
      final p2 = Offset(center.dx + (r - 6) * math.cos(angle), center.dy + (r - 6) * math.sin(angle));
      canvas.drawLine(p1, p2, paint);
    }
  }

  void _drawArcSegments(Canvas canvas, Offset center, double r, Color color) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    final rect = Rect.fromCircle(center: center, radius: r);
    canvas.drawArc(rect, 0, math.pi / 3, false, paint);
    canvas.drawArc(rect, 2 * math.pi / 3, math.pi / 3, false, paint);
    canvas.drawArc(rect, 4 * math.pi / 3, math.pi / 3, false, paint);
  }

  void _drawCrosshairs(Canvas canvas, Offset center, double r, Color color) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.5)
      ..strokeWidth = 1.0;

    canvas.drawLine(Offset(center.dx - r - 4, center.dy), Offset(center.dx - r + 8, center.dy), paint);
    canvas.drawLine(Offset(center.dx + r - 8, center.dy), Offset(center.dx + r + 4, center.dy), paint);
    canvas.drawLine(Offset(center.dx, center.dy - r - 4), Offset(center.dx, center.dy - r + 8), paint);
    canvas.drawLine(Offset(center.dx, center.dy + r - 8), Offset(center.dx, center.dy + r + 4), paint);
  }

  void _drawWaveRings(Canvas canvas, Offset center, double radius, Color color) {
    for (int i = 1; i <= 3; i++) {
      final ringRadius = radius * (0.50 + i * 0.12);
      final ringPaint = Paint()
        ..color = color.withValues(alpha: (0.30 / i) * breathValue)
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
