import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../config/theme_config.dart';
import '../config/animation_config.dart';
import '../providers/assistant_provider.dart';

/// Mic activation button with ripple effect.
///
/// Enabled only when power is ON. Shows a pulsing ripple ring
/// while actively listening.
class MicButton extends StatefulWidget {
  final bool isPoweredOn;
  final AssistantStatus status;
  final VoidCallback onPressed;

  const MicButton({
    super.key,
    required this.isPoweredOn,
    required this.status,
    required this.onPressed,
  });

  @override
  State<MicButton> createState() => _MicButtonState();
}

class _MicButtonState extends State<MicButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _rippleCtrl;
  late Animation<double> _rippleAnim;

  @override
  void initState() {
    super.initState();
    _rippleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _rippleAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _rippleCtrl, curve: Curves.easeOut),
    );
  }

  @override
  void didUpdateWidget(MicButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.status == AssistantStatus.listening) {
      _rippleCtrl.repeat();
    } else {
      _rippleCtrl.stop();
      _rippleCtrl.reset();
    }
  }

  @override
  void dispose() {
    _rippleCtrl.dispose();
    super.dispose();
  }

  bool get _isListening => widget.status == AssistantStatus.listening;
  bool get _isEnabled =>
      widget.isPoweredOn && widget.status != AssistantStatus.processing;

  Future<void> _handleTap() async {
    if (!_isEnabled) return;
    HapticFeedback.lightImpact();
    widget.onPressed();
  }

  @override
  Widget build(BuildContext context) {
    final color = _isListening
        ? ThemeConfig.statusListening
        : ThemeConfig.primary;

    return GestureDetector(
      onTap: _handleTap,
      child: SizedBox(
        width: 80,
        height: 80,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Ripple ring (listening only)
            if (_isListening)
              AnimatedBuilder(
                animation: _rippleAnim,
                builder: (_, __) => Transform.scale(
                  scale: 0.6 + _rippleAnim.value * 0.8,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: ThemeConfig.statusListening
                            .withValues(alpha: 1.0 - _rippleAnim.value),
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ),

            // Button body
            AnimatedContainer(
              duration: AnimationConfig.powerToggleDuration,
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: _isEnabled
                      ? [
                          color.withValues(alpha: 0.25),
                          color.withValues(alpha: 0.08),
                        ]
                      : [
                          ThemeConfig.surface,
                          ThemeConfig.surface,
                        ],
                ),
                border: Border.all(
                  color: _isEnabled
                      ? color.withValues(alpha: 0.6)
                      : ThemeConfig.border,
                  width: 1.5,
                ),
                boxShadow: _isEnabled
                    ? [
                        BoxShadow(
                          color: color.withValues(alpha: 0.3),
                          blurRadius: 16,
                          spreadRadius: 1,
                        ),
                      ]
                    : [],
              ),
              child: Icon(
                _isListening
                    ? Icons.mic_rounded
                    : Icons.mic_none_rounded,
                color: _isEnabled
                    ? color
                    : ThemeConfig.textMuted,
                size: 28,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
