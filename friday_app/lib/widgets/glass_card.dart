import 'package:flutter/material.dart';
import '../config/theme_config.dart';

/// Glassmorphism-style container with frosted backdrop, subtle border, and
/// optional glow. Used as the base for all floating panels in the UI.
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;
  final Color? glowColor;
  final double glowRadius;
  final double opacity;

  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.borderRadius = 20,
    this.glowColor,
    this.glowRadius = 0,
    this.opacity = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 250),
      opacity: opacity,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius),
          color: ThemeConfig.surfaceElevated.withValues(alpha: 0.72),
          border: Border.all(
            color: ThemeConfig.border.withValues(alpha: 0.7),
            width: 1,
          ),
          boxShadow: [
            // Subtle dark drop shadow
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
            // Glow layer (conditional)
            if (glowColor != null && glowRadius > 0)
              BoxShadow(
                color: glowColor!.withValues(alpha: 0.18),
                blurRadius: glowRadius,
                spreadRadius: 2,
              ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius),
          child: Padding(
            padding: padding ?? EdgeInsets.zero,
            child: child,
          ),
        ),
      ),
    );
  }
}
