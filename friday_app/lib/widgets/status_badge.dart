import 'package:flutter/material.dart';
import '../config/theme_config.dart';
import '../providers/assistant_provider.dart';

/// Animated status badge showing the current assistant power/pipeline state.
///
/// Transitions between states with a smooth fade + scale micro-animation.
///
/// Examples:
///   🔴 OFF        → dark, dim
///   🟢 LISTENING  → cyan pulse dot
///   🟡 PROCESSING → amber dot
///   🔵 SPEAKING   → blue dot
class StatusBadge extends StatefulWidget {
  final AssistantStatus status;
  final bool isPoweredOn;

  const StatusBadge({
    super.key,
    required this.status,
    required this.isPoweredOn,
  });

  @override
  State<StatusBadge> createState() => _StatusBadgeState();
}

class _StatusBadgeState extends State<StatusBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.7, end: 1.0)
        .animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  _StatusMeta get _meta {
    if (!widget.isPoweredOn) {
      return const _StatusMeta(
        label: 'OFF',
        color: ThemeConfig.statusOff,
        icon: Icons.power_settings_new_rounded,
      );
    }
    return switch (widget.status) {
      AssistantStatus.idle => const _StatusMeta(
          label: 'IDLE',
          color: ThemeConfig.primaryDim,
          icon: Icons.radio_button_unchecked,
        ),
      AssistantStatus.listening => const _StatusMeta(
          label: 'LISTENING',
          color: ThemeConfig.statusListening,
          icon: Icons.mic_rounded,
        ),
      AssistantStatus.processing => const _StatusMeta(
          label: 'PROCESSING',
          color: ThemeConfig.statusProcessing,
          icon: Icons.auto_awesome_rounded,
        ),
      AssistantStatus.speaking => const _StatusMeta(
          label: 'SPEAKING',
          color: ThemeConfig.statusSpeaking,
          icon: Icons.volume_up_rounded,
        ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final meta = _meta;
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (child, anim) => FadeTransition(
        opacity: anim,
        child: ScaleTransition(scale: anim, child: child),
      ),
      child: Container(
        key: ValueKey(meta.label),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          color: meta.color.withValues(alpha: 0.12),
          border: Border.all(color: meta.color.withValues(alpha: 0.4), width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Pulsing dot
            AnimatedBuilder(
              animation: _pulseAnim,
              builder: (_, __) => Opacity(
                opacity: widget.isPoweredOn ? _pulseAnim.value : 1.0,
                child: Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: meta.color,
                    boxShadow: [
                      BoxShadow(
                        color: meta.color.withValues(alpha: 0.7),
                        blurRadius: 6,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              meta.label,
              style: TextStyle(
                color: meta.color,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 2.0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusMeta {
  final String label;
  final Color color;
  final IconData icon;
  const _StatusMeta({
    required this.label,
    required this.color,
    required this.icon,
  });
}
