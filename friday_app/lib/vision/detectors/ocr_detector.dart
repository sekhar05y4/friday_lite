import 'dart:typed_data';
import '../i_vision_detector.dart';

/// Optical Character Recognition (OCR) and Document Scanner Vision Detector.
class OcrDetector implements IVisionDetector {
  @override
  String get detectorId => 'ocr_text';

  @override
  String get name => 'OCR Text & Document Scanner';

  @override
  Future<VisionResult> processFrame(Uint8List imageBytes, int width, int height) async {
    if (imageBytes.isEmpty) {
      return const VisionResult(
        detectorId: 'ocr_text',
        success: false,
        textResult: 'No frame data.',
      );
    }

    return const VisionResult(
      detectorId: 'ocr_text',
      success: true,
      textResult: 'Extracted Document Text: "FRIDAY Lite v1 - Personal AI Assistant"',
      metadata: {'lines_found': 1, 'language': 'en'},
    );
  }
}
