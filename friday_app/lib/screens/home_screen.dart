import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/theme_config.dart';
import '../core/friday_core.dart';
import '../core/power_mode.dart';
import '../providers/assistant_provider.dart';
import '../services/telemetry_service.dart';
import '../widgets/conversation_panel.dart';
import '../widgets/glowing_orb.dart';
import '../widgets/hud_telemetry_bar.dart';
import '../widgets/hud_token_meter.dart';
import '../widgets/mic_button.dart';
import '../widgets/power_button.dart';
import '../widgets/status_badge.dart';
import 'settings_screen.dart';

/// The primary assistant interface — Jarvis Sci-Fi HUD Dashboard.
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
          tooltip: 'Settings & Diagnostics',
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

class _HomeBody extends StatefulWidget {
  @override
  State<_HomeBody> createState() => _HomeBodyState();
}

class _HomeBodyState extends State<_HomeBody> {
  bool _wasOn = false;

  @override
  void initState() {
    super.initState();
    TelemetryService.instance.startPolling();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final core = context.read<FridayCore>();
    final isOn = core.powerMode.isOn;

    if (isOn && !_wasOn) {
      _wasOn = true;
      final assistant = context.read<AssistantProvider>();
      Future.delayed(const Duration(milliseconds: 400), () {
        if (mounted) assistant.speak('Hello. I am FRIDAY. System telemetry and AI core active.');
      });
    } else if (!isOn) {
      _wasOn = false;
    }
  }

  @override
  void dispose() {
    TelemetryService.instance.stopPolling();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final core = context.watch<FridayCore>();
    final assistant = context.watch<AssistantProvider>();
    final isPoweredOn = core.powerMode.isOn;

    return ListenableBuilder(
      listenable: TelemetryService.instance,
      builder: (context, _) {
        final telemetryData = TelemetryService.instance.data;

        return Stack(
          children: [
            // Ambient background gradient
            _AmbientBackground(
              status: assistant.status,
              isPoweredOn: isPoweredOn,
            ),

            // Main Sci-Fi HUD content
            SafeArea(
              child: Column(
                children: [
                  const SizedBox(height: 8),

                  // ── Top Telemetry HUD Bar ──────────────────────────────
                  HudTelemetryBar(
                    data: telemetryData,
                    isPoweredOn: isPoweredOn,
                  ),

                  const SizedBox(height: 12),

                  // ── Arc Reactor Voice Core ──────────────────────────────
                  Expanded(
                    flex: 5,
                    child: Center(
                      child: GlowingOrb(
                        status: assistant.status,
                        size: MediaQuery.of(context).size.width * 0.58,
                      ),
                    ),
                  ),

                  // ── Status badge ─────────────────────────────────────────
                  StatusBadge(
                    status: assistant.status,
                    isPoweredOn: isPoweredOn,
                  ),

                  const SizedBox(height: 12),

                  // ── Conversation panel ───────────────────────────────────
                  Expanded(
                    flex: 4,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: ConversationPanel(
                        messages: assistant.messages,
                        interimText: assistant.interimText,
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // ── Bottom Token & Network Meter ────────────────────────
                  HudTokenMeter(data: telemetryData),

                  const SizedBox(height: 12),

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

                  const SizedBox(height: 16),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

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
      AssistantStatus.idle => ThemeConfig.primary.withValues(alpha: 0.04),
      AssistantStatus.listening =>
        ThemeConfig.statusListening.withValues(alpha: 0.08),
      AssistantStatus.processing =>
        ThemeConfig.statusProcessing.withValues(alpha: 0.06),
      AssistantStatus.speaking =>
        ThemeConfig.statusSpeaking.withValues(alpha: 0.06),
    };
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 600),
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: const Alignment(0, -0.2),
          radius: 1.1,
          colors: [
            _ambientColor,
            ThemeConfig.background,
          ],
        ),
      ),
    );
  }
}

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
              const SizedBox(height: 6),
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
              const SizedBox(height: 6),
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
        'F R I D A Y   H U D',
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.white,
              letterSpacing: 6,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }
}
