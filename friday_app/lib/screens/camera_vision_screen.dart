import 'package:flutter/material.dart';

import '../config/theme_config.dart';
import '../vision/camera_manager.dart';
import '../vision/i_vision_detector.dart';
import '../widgets/glass_card.dart';

/// Camera Vision Platform UI Screen for FRIDAY.
///
/// Features:
///   - Real-time Camera Preview Viewport
///   - Mode Selector Bar: Photo, QR Scanner, OCR Text, Face, Object
///   - Instant Analysis & Visual Bounding Overlays
class CameraVisionScreen extends StatefulWidget {
  const CameraVisionScreen({super.key});

  @override
  State<CameraVisionScreen> createState() => _CameraVisionScreenState();
}

class _CameraVisionScreenState extends State<CameraVisionScreen> {
  String _selectedMode = 'qr_barcode';
  List<VisionResult> _results = [];
  bool _isAnalyzing = false;

  final Map<String, String> _modeNames = {
    'qr_barcode': 'QR & Barcode',
    'ocr_text': 'OCR Text',
    'face_detection': 'Face Detection',
    'object_detection': 'Object Detection',
  };

  @override
  void initState() {
    super.initState();
    CameraManager.instance.initialize();
  }

  Future<void> _captureAndAnalyze() async {
    setState(() => _isAnalyzing = true);

    final results = await CameraManager.instance.captureAndAnalyze(
      targetDetectorId: _selectedMode,
    );

    if (mounted) {
      setState(() {
        _results = results;
        _isAnalyzing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThemeConfig.background,
      appBar: AppBar(
        title: Text(
          'CAMERA VISION',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontSize: 14,
                letterSpacing: 4,
                color: ThemeConfig.textPrimary,
              ),
        ),
        centerTitle: true,
        backgroundColor: ThemeConfig.background,
        iconTheme: const IconThemeData(color: ThemeConfig.textSecondary),
      ),
      body: Column(
        children: [
          // ── Camera Preview Viewport ───────────────────────────────────────
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black45,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: ThemeConfig.primary.withValues(alpha: 0.3)),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.linked_camera_rounded, color: ThemeConfig.primaryDim, size: 64),
                      SizedBox(height: 12),
                      Text(
                        'CAMERA PREVIEW VIEWPORT',
                        style: TextStyle(color: ThemeConfig.textMuted, fontSize: 12, letterSpacing: 2),
                      ),
                    ],
                  ),
                  if (_isAnalyzing)
                    const CircularProgressIndicator(color: ThemeConfig.primary),
                ],
              ),
            ),
          ),

          // ── Mode Selector Chips ──────────────────────────────────────────
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: _modeNames.entries.map((e) {
                final isSelected = _selectedMode == e.key;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(e.value),
                    selected: isSelected,
                    selectedColor: ThemeConfig.primary.withValues(alpha: 0.3),
                    backgroundColor: ThemeConfig.surface,
                    labelStyle: TextStyle(
                      color: isSelected ? ThemeConfig.primary : ThemeConfig.textSecondary,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    onSelected: (_) => setState(() => _selectedMode = e.key),
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 12),

          // ── Vision Analysis Results Card ─────────────────────────────────
          if (_results.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GlassCard(
                child: Row(
                  children: [
                    const Icon(Icons.psychology_rounded, color: ThemeConfig.accent, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _results.first.textResult,
                        style: const TextStyle(color: ThemeConfig.textPrimary, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 16),

          // ── Capture & Analyze Button ─────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _isAnalyzing ? null : _captureAndAnalyze,
                icon: const Icon(Icons.center_focus_strong_rounded),
                label: Text('ANALYZE MODE (${_modeNames[_selectedMode]?.toUpperCase()})'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: ThemeConfig.primary,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
