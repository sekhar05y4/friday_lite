import 'dart:typed_data';

/// Common data descriptor for vision analysis results.
class VisionResult {
  final String detectorId;
  final bool success;
  final String textResult;
  final Map<String, dynamic> metadata;

  const VisionResult({
    required this.detectorId,
    required this.success,
    required this.textResult,
    this.metadata = const {},
  });
}

/// Abstract interface for modular vision processing plugins.
///
/// Implementations can plug in Google ML Kit, OpenCV, TensorFlow Lite,
/// or Cloud AI (Gemini Vision) without touching the [VisionPipeline].
abstract class IVisionDetector {
  String get detectorId;
  String get name;
  
  /// Process raw image bytes or frame buffer.
  Future<VisionResult> processFrame(Uint8List imageBytes, int width, int height);
}
