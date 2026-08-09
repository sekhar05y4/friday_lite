import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/theme_config.dart';
import '../core/friday_core.dart';
import '../core/power_mode.dart';
import '../providers/assistant_provider.dart';
import '../services/telemetry_service.dart';
import '../widgets/audio_waveform_widget.dart';
import '../widgets/conversation_panel.dart';
import '../widgets/cpu_ram_bar_chart.dart';
import '../widgets/glowing_orb.dart';
import '../widgets/header_banner_widget.dart';
import '../widgets/hud_token_meter.dart';
import '../widgets/mic_button.dart';
import '../widgets/power_button.dart';
import '../widgets/radar_chart_widget.dart';
import '../widgets/tech_status_grid.dart';
import 'settings_screen.dart';

/// Primary interface — Sci-Fi HUD Infographic Dashboard matching reference UI image.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF071019),
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
        // Voice Briefing Trigger
        IconButton(
          icon: const Icon(Icons.campaign_rounded),
          color: const Color(0xFF00FF88),
          tooltip: 'Wake Up Voice Briefing',
          onPressed: () {
            context.read<AssistantProvider>().triggerWakeUpBriefing();
          },
        ),

        // Global Copy Chat Log
        IconButton(
          icon: const Icon(Icons.copy_all_rounded),
          color: const Color(0xFF00F0FF),
          tooltip: 'Copy Chat Log',
          onPressed: () {
            final msgs = context.read<AssistantProvider>().messages;
            ConversationPanel.copyFullChatLog(context, msgs);
          },
        ),

        // Settings & Diagnostics
        IconButton(
          icon: const Icon(Icons.tune_rounded),
          color: ThemeConfig.textSecondary,
          tooltip: 'Settings & Diagnostics',
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SettingsScreen()),
          ),
        ),
        const SizedBox(width: 4),
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<AssistantProvider>().startListening();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final core = context.read<FridayCore>();
    final isOn = core.powerMode.isOn;

    if (isOn && !_wasOn) {
      _wasOn = true;
      final assistant = context.read<AssistantProvider>();
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) assistant.triggerWakeUpBriefing();
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
            // Dark Navy Grid Background
            _SciFiGridBackground(status: assistant.status),

            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: Column(
                  children: [
                    // ── TOP ROW: Waveform | Header Banner | Per-Core CPU Chart ────
                    SizedBox(
                      height: 76,
                      child: Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: AudioWaveformWidget(status: assistant.status),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 4,
                            child: HeaderBannerWidget(status: assistant.status),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 3,
                            child: CpuRamBarChart(data: telemetryData),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 6),

                    // ── MIDDLE ROW: Tech Grid | Bounded Arc Reactor Core | Spider Chart
                    Expanded(
                      flex: 5,
                      child: Row(
                        children: [
                          // Left Tech Status Grid & Scanner
                          Expanded(
                            flex: 3,
                            child: TechStatusGrid(data: telemetryData),
                          ),
                          const SizedBox(width: 8),

                          // Center Bounded Arc Reactor Core
                          Expanded(
                            flex: 4,
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                final size = math.min(constraints.maxHeight * 0.82, constraints.maxWidth * 0.82).clamp(100.0, 190.0);
                                return Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      GlowingOrb(
                                        status: assistant.status,
                                        size: size,
                                      ),
                                      const SizedBox(height: 4),
                                      const Text(
                                        'FRIDAY SYSTEM CONTROL',
                                        style: TextStyle(
                                          color: Color(0xFF00F0FF),
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 1.8,
                                          fontFamily: 'monospace',
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 8),

                          // Right Radar Spider Chart
                          Expanded(
                            flex: 3,
                            child: RadarChartWidget(data: telemetryData),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 6),

                    // ── CONVERSATION LOG PANEL ─────────────────────────────
                    Expanded(
                      flex: 4,
                      child: ConversationPanel(
                        messages: assistant.messages,
                        interimText: assistant.interimText,
                      ),
                    ),

                    const SizedBox(height: 4),

                    // ── BOTTOM TOKEN METER ─────────────────────────────────
                    HudTokenMeter(data: telemetryData),

                    const SizedBox(height: 6),

                    // ── CONTROL BUTTONS ────────────────────────────────────
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        PowerButton(
                          isOn: isPoweredOn,
                          onToggle: () => core.togglePower(),
                        ),
                        MicButton(
                          isPoweredOn: isPoweredOn,
                          status: assistant.status,
                          onPressed: () {
                            if (assistant.status == AssistantStatus.listening) {
                              assistant.stopListening();
                            } else {
                              assistant.startListening();
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _SciFiGridBackground extends StatelessWidget {
  final AssistantStatus status;

  const _SciFiGridBackground({required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF071019),
      ),
      child: CustomPaint(
        painter: _BackgroundGridPainter(),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _BackgroundGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = const Color(0x0A00F0FF)
      ..strokeWidth = 0.8;

    for (double x = 0; x < size.width; x += 24) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += 24) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
  }

  @override
  bool shouldRepaint(_BackgroundGridPainter old) => false;
}

class _FridayTitle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Text(
      'F R I D A Y   H U D',
      style: TextStyle(
        color: Color(0xFF00F0FF),
        letterSpacing: 4,
        fontSize: 14,
        fontWeight: FontWeight.bold,
        fontFamily: 'monospace',
      ),
    );
  }
}
