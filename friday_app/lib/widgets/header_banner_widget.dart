import 'package:flutter/material.dart';

import '../providers/assistant_provider.dart';

/// Top-Center Sci-Fi Double Angled Header Banner (matching reference UI image).
class HeaderBannerWidget extends StatelessWidget {
  final AssistantStatus status;

  const HeaderBannerWidget({super.key, required this.status});

  String get _statusText => switch (status) {
        AssistantStatus.idle => 'SYSTEM ONLINE',
        AssistantStatus.listening => 'LISTENING MODE',
        AssistantStatus.processing => 'THINKING MODE',
        AssistantStatus.speaking => 'STREAMING VOICE',
      };

  Color get _statusColor => switch (status) {
        AssistantStatus.idle => const Color(0xFF00F0FF),
        AssistantStatus.listening => const Color(0xFF00FF88),
        AssistantStatus.processing => const Color(0xFFE056FD),
        AssistantStatus.speaking => const Color(0xFF2ED573),
      };

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Top angled banner
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0x1F00F0FF),
            border: Border.all(color: const Color(0xFF00F0FF), width: 1.2),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'ADVANCED TECHNOLOGY',
                style: TextStyle(
                  color: Color(0xFF00F0FF),
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2.0,
                  fontFamily: 'monospace',
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                color: const Color(0xFF00F0FF),
                child: const Text(
                  'INFOGRAPHICS +',
                  style: TextStyle(
                    color: Color(0xFF071019),
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),

        // Bottom angled status banner
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 3),
          decoration: BoxDecoration(
            color: _statusColor.withValues(alpha: 0.15),
            border: Border.all(color: _statusColor.withValues(alpha: 0.6), width: 1),
            borderRadius: BorderRadius.circular(2),
          ),
          child: Text(
            _statusText,
            style: TextStyle(
              color: _statusColor,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 2.5,
              fontFamily: 'monospace',
            ),
          ),
        ),
      ],
    );
  }
}
