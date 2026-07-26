import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/theme_config.dart';
import '../core/friday_core.dart';
import '../core/power_mode.dart';
import '../providers/assistant_provider.dart';
import '../widgets/glowing_orb.dart';
import '../widgets/status_badge.dart';
import '../widgets/power_button.dart';
import '../widgets/mic_button.dart';
import '../widgets/conversation_panel.dart';
import 'settings_screen.dart';

/// The primary assistant interface.
///
/// Layout (top → bottom):
///   ┌─ AppBar: FRIDAY title + settings icon
///   ├─ GlowingOrb (center, takes ~42% of vertical space)
///   ├─ StatusBadge
///   ├─ Interim / conversation transcript
///   └─ Control bar: Power button + Mic button
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThemeConfig.background,
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(context),
      body: _HomeBody(),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      title: _FridayTitle(),
      actions: [
        IconButton(
          icon: const Icon(Icons.tune_rounded),
          color: ThemeConfig.textSecondary,
          tooltip: 'Settings',
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SettingsScreen()),
          ),
        ),
        const SizedBox(width: 8),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Home body — rebuilt on state change
// ---------------------------------------------------------------------------

class _HomeBody extends StatefulWidget {
  @override
  State<_HomeBody> createState() => _HomeBodyState();
}

class _HomeBodyState extends State<_HomeBody> {
  bool _wasOn = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final core = context.read<FridayCore>();
    final isOn = core.powerMode.isOn;

    // Greet on first power-on
    if (isOn && !_wasOn) {
      _wasOn = true;
      final assistant = context.read<AssistantProvider>();
      Future.delayed(const Duration(milliseconds: 400), () {
        if (mounted) assistant.speak('Hello. I am FRIDAY. How can I help you?');
      });
    } else if (!isOn) {
      _wasOn = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final core = context.watch<FridayCore>();
    final assistant = context.watch<AssistantProvider>();
    final isPoweredOn = core.powerMode.isOn;

    return Stack(
      children: [
        // Ambient background gradient
        _AmbientBackground(
          status: assistant.status,
          isPoweredOn: isPoweredOn,
        ),

        // Main content
        SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 16),

              // ── Orb section ──────────────────────────────────────────
              Expanded(
                flex: 5,
                child: Center(
                  child: GlowingOrb(
                    status: assistant.status,
                    size: MediaQuery.of(context).size.width * 0.60,
                  ),
                ),
              ),

              // ── Status badge ─────────────────────────────────────────
              StatusBadge(
                status: assistant.status,
                isPoweredOn: isPoweredOn,
              ),

              const SizedBox(height: 20),

              // ── Conversation panel ───────────────────────────────────
              Expanded(
                flex: 4,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: ConversationPanel(
                    messages: assistant.messages,
                    interimText: assistant.interimText,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // ── Control bar ──────────────────────────────────────────
              _ControlBar(
                isPoweredOn: isPoweredOn,
                status: assistant.status,
                onPowerToggle: () => core.togglePower(),
                onMicPressed: () {
                  if (assistant.status == AssistantStatus.listening) {
                    assistant.stopListening();
                  } else {
                    assistant.startListening();
                  }
                },
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Ambient radial gradient background
// ---------------------------------------------------------------------------

class _AmbientBackground extends StatelessWidget {
  final AssistantStatus status;
  final bool isPoweredOn;

  const _AmbientBackground({
    required this.status,
    required this.isPoweredOn,
  });

  Color get _ambientColor {
    if (!isPoweredOn) return ThemeConfig.statusOff.withValues(alpha: 0.04);
    return switch (status) {
      AssistantStatus.idle => ThemeConfig.primary.withValues(alpha: 0.03),
      AssistantStatus.listening =>
        ThemeConfig.statusListening.withValues(alpha: 0.06),
      AssistantStatus.processing =>
        ThemeConfig.statusProcessing.withValues(alpha: 0.05),
      AssistantStatus.speaking =>
        ThemeConfig.statusSpeaking.withValues(alpha: 0.05),
    };
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 600),
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: const Alignment(0, -0.3),
          radius: 1.0,
          colors: [
            _ambientColor,
            ThemeConfig.background,
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Control bar (Power + Mic)
// ---------------------------------------------------------------------------

class _ControlBar extends StatelessWidget {
  final bool isPoweredOn;
  final AssistantStatus status;
  final VoidCallback onPowerToggle;
  final VoidCallback onMicPressed;

  const _ControlBar({
    required this.isPoweredOn,
    required this.status,
    required this.onPowerToggle,
    required this.onMicPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Power button
          Column(
            children: [
              PowerButton(
                isOn: isPoweredOn,
                onToggle: onPowerToggle,
              ),
              const SizedBox(height: 8),
              Text(
                isPoweredOn ? 'TURN OFF' : 'TURN ON',
                style: const TextStyle(
                  color: ThemeConfig.textMuted,
                  fontSize: 10,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),

          // Mic button (larger, centre)
          Column(
            children: [
              MicButton(
                isPoweredOn: isPoweredOn,
                status: status,
                onPressed: onMicPressed,
              ),
              const SizedBox(height: 8),
              Text(
                status == AssistantStatus.listening ? 'STOP' : 'SPEAK',
                style: const TextStyle(
                  color: ThemeConfig.textMuted,
                  fontSize: 10,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// FRIDAY animated title
// ---------------------------------------------------------------------------

class _FridayTitle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (bounds) => const LinearGradient(
        colors: [ThemeConfig.primary, ThemeConfig.accent],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      ).createShader(bounds),
      child: Text(
        'F R I D A Y',
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.white,
              letterSpacing: 8,
              fontSize: 18,
            ),
      ),
    );
  }
}
