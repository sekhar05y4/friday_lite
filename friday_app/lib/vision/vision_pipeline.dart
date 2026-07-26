import 'dart:typed_data';

import '../utils/logger.dart';
import 'detectors/face_detector.dart';
import 'detectors/object_detector.dart';
import 'detectors/ocr_detector.dart';
import 'detectors/qr_detector.dart';
import 'i_vision_detector.dart';
import 'image_processor.dart';

/// Centralized Vision Pipeline for FRIDAY.
///
/// Coordinates frame ingestion, preprocessing via [ImageProcessor],
/// and dispatching to registered [IVisionDetector] plugins.
///
/// **Architecture Principle**: Does NOT tightly couple any specific AI model.
/// New models (Gemini Vision, OpenCV, ML Kit, TensorFlow Lite) are added simply by
/// implementing [IVisionDetector] and registering them with [registerDetector].
class VisionPipeline {
  VisionPipeline._() {
    // Register built-in detector plugins
    registerDetector(QRDetector());
    registerDetector(OcrDetector());
    registerDetector(FaceDetectorPlugin());
    registerDetector(ObjectDetectorPlugin());
  }

  static final VisionPipeline instance = VisionPipeline._();

  final Map<String, IVisionDetector> _detectors = {};

  /// Register a modular vision detector plugin.
  void registerDetector(IVisionDetector detector) {
    _detectors[detector.detectorId] = detector;
    FridayLogger.log(
      LogCategory.assistant,
      'VisionPipeline: registered detector "${detector.name}" (${detector.detectorId})',
    );
  }

  /// Process an image frame through a specific detector or all active detectors.
  Future<List<VisionResult>> analyzeFrame({
    required Uint8List rawFrameBytes,
    required int width,
    required int height,
    String? targetDetectorId,
  }) async {
    final preprocessed = ImageProcessor.instance.preprocessFrame(rawFrameBytes, width, height);

    if (targetDetectorId != null && _detectors.containsKey(targetDetectorId)) {
      final detector = _detectors[targetDetectorId]!;
      final result = await detector.processFrame(preprocessed, width, height);
      return [result];
    }

    final results = <VisionResult>[];
    for (final detector in _detectors.values) {
      try {
        final result = await detector.processFrame(preprocessed, width, height);
        results.add(result);
      } catch (e) {
        FridayLogger.error(
          LogCategory.error,
          'VisionPipeline: detector "${detector.detectorId}" failed: $e',
        );
      }
    }
    return results;
  }

  List<String> get registeredDetectorNames =>
      _detectors.values.map((d) => d.name).toList();
}
