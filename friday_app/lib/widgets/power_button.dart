import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../config/theme_config.dart';
import '../config/animation_config.dart';

/// Premium power toggle button with ON/OFF animated state transition.
///
/// Renders a circular button with a glowing ring that lights up when ON.
/// Provides haptic feedback on toggle.
class PowerButton extends StatefulWidget {
  final bool isOn;
  final VoidCallback onToggle;

  const PowerButton({
    super.key,
    required this.isOn,
    required this.onToggle,
  });

  @override
  State<PowerButton> createState() => _PowerButtonState();
}

class _PowerButtonState extends State<PowerButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _scaleCtrl;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _scaleCtrl = AnimationController(
      vsync: this,
      duration: AnimationConfig.microFeedbackDuration,
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.90).animate(
      CurvedAnimation(parent: _scaleCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scaleCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleTap() async {
    HapticFeedback.mediumImpact();
    await _scaleCtrl.forward();
    await _scaleCtrl.reverse();
    widget.onToggle();
  }

  @override
  Widget build(BuildContext context) {
    final activeColor =
        widget.isOn ? ThemeConfig.statusOff : ThemeConfig.statusListening;

    return GestureDetector(
      onTap: _handleTap,
      child: AnimatedBuilder(
        animation: _scaleAnim,
        builder: (_, child) => Transform.scale(
          scale: _scaleAnim.value,
          child: child,
        ),
        child: AnimatedContainer(
          duration: AnimationConfig.powerToggleDuration,
          curve: Curves.easeInOut,
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: activeColor.withValues(alpha: 0.12),
            border: Border.all(
              color: activeColor.withValues(alpha: 0.7),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: activeColor.withValues(alpha: 0.35),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Center(
            child: AnimatedSwitcher(
              duration: AnimationConfig.powerToggleDuration,
              child: Icon(
                widget.isOn
                    ? Icons.power_settings_new_rounded
                    : Icons.power_settings_new_outlined,
                key: ValueKey(widget.isOn),
                color: activeColor,
                size: 28,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
