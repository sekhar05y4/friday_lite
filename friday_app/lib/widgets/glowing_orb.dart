import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../config/theme_config.dart';
import '../config/animation_config.dart';
import '../providers/assistant_provider.dart';

/// Animated glowing AI orb that visually represents the assistant's state.
///
/// Uses [CustomPainter] with layered radial gradients and sine-wave breathing
/// to create a premium, futuristic feel — no external animation libraries needed.
///
/// Colours per state:
///   OFF         → deep grey-red dim pulse
///   Listening   → electric cyan rapid wave
///   Processing  → amber swirl
///   Speaking    → violet-blue soundwave
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
  // Breathing animation (scale + opacity pulse)
  late AnimationController _breathController;
  late Animation<double> _breathAnim;

  // Rotation for the inner swirl layer
  late AnimationController _rotController;
  late Animation<double> _rotAnim;

  // Colour transition between states
  late AnimationController _colorController;

  // Store previous colours for smooth lerp transitions
  List<Color> _fromColors = ThemeConfig.orbOff;
  List<Color> _toColors = ThemeConfig.orbOff;

  @override
  void initState() {
    super.initState();

    _breathController = AnimationController(
      vsync: this,
      duration: _breathDuration(widget.status),
    )..repeat(reverse: true);

    _breathAnim = Tween<double>(begin: 0.88, end: 1.0).animate(
      CurvedAnimation(parent: _breathController, curve: Curves.easeInOut),
    );

    _rotController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
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
      // Snapshot current lerped colours as the new "from"
      final t = _colorController.value;
      _fromColors = List.generate(
        3,
        (i) => Color.lerp(_fromColors[i], _toColors[i], t)!,
      );
      _toColors = _colorsForStatus(widget.status);
      _colorController.forward(from: 0);

      // Adjust breath speed
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

  // ---------------------------------------------------------------------------

  List<Color> _colorsForStatus(AssistantStatus s) => switch (s) {
        AssistantStatus.idle => ThemeConfig.orbOff,
        AssistantStatus.listening => ThemeConfig.orbListening,
        AssistantStatus.processing => ThemeConfig.orbProcessing,
        AssistantStatus.speaking => ThemeConfig.orbSpeaking,
      };

  Duration _breathDuration(AssistantStatus s) => switch (s) {
        AssistantStatus.idle => const Duration(milliseconds: 3200),
        AssistantStatus.listening => const Duration(milliseconds: 900),
        AssistantStatus.processing => const Duration(milliseconds: 600),
        AssistantStatus.speaking => const Duration(milliseconds: 750),
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
              painter: _OrbPainter(
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

class _OrbPainter extends CustomPainter {
  final List<Color> colors;
  final double rotation;
  final double breathValue;
  final AssistantStatus status;

  const _OrbPainter({
    required this.colors,
    required this.rotation,
    required this.breathValue,
    required this.status,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // --- Layer 1: Outer glow ring ---
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          colors[1].withValues(alpha: 0.18 * breathValue),
          colors[0].withValues(alpha: 0),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, glowPaint);

    // --- Layer 2: Mid glow ring ---
    final midGlowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          colors[1].withValues(alpha: 0.35 * breathValue),
          colors[0].withValues(alpha: 0.05),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius * 0.78));
    canvas.drawCircle(center, radius * 0.78, midGlowPaint);

    // --- Layer 3: Rotating inner swirl ---
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotation);
    canvas.translate(-center.dx, -center.dy);

    final swirlPaint = Paint()
      ..shader = SweepGradient(
        colors: [
          colors[1].withValues(alpha: 0.0),
          colors[1].withValues(alpha: 0.55),
          colors[2].withValues(alpha: 0.3),
          colors[1].withValues(alpha: 0.0),
        ],
        stops: const [0.0, 0.3, 0.6, 1.0],
        transform: GradientRotation(rotation),
      ).createShader(Rect.fromCircle(center: center, radius: radius * 0.62));
    canvas.drawCircle(center, radius * 0.62, swirlPaint);
    canvas.restore();

    // --- Layer 4: Core orb ---
    final corePaint = Paint()
      ..shader = RadialGradient(
        colors: [
          colors[1].withValues(alpha: 0.9),
          colors[0].withValues(alpha: 0.85),
          colors[2].withValues(alpha: 0.6),
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius * 0.5));
    canvas.drawCircle(center, radius * 0.5, corePaint);

    // --- Layer 5: Highlight specular ---
    final highlightPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.4, -0.4),
        colors: [
          Colors.white.withValues(alpha: 0.22),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius * 0.5));
    canvas.drawCircle(center, radius * 0.5, highlightPaint);

    // --- Layer 6: Sound wave rings (speaking mode) ---
    if (status == AssistantStatus.speaking) {
      _drawWaveRings(canvas, center, radius, colors[1]);
    }

    // --- Layer 7: Crisp border ---
    final borderPaint = Paint()
      ..color = colors[1].withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(center, radius * 0.5, borderPaint);
  }

  void _drawWaveRings(
      Canvas canvas, Offset center, double radius, Color color) {
    for (int i = 1; i <= 3; i++) {
      final ringRadius = radius * (0.55 + i * 0.14);
      final ringPaint = Paint()
        ..color = color.withValues(alpha: (0.25 / i) * breathValue)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;
      canvas.drawCircle(center, ringRadius, ringPaint);
    }
  }

  @override
  bool shouldRepaint(_OrbPainter old) =>
      old.colors != colors ||
      old.rotation != rotation ||
      old.breathValue != breathValue ||
      old.status != status;
}
