import '../core/event_bus.dart';
import '../core/events.dart';
import '../interfaces/i_action_module.dart';
import '../models/command_result.dart';
import '../models/module_capability.dart';
import '../vision/camera_manager.dart';
import '../utils/logger.dart';

/// Camera Vision Action Module for FRIDAY.
///
/// Features:
///   - Camera Preview & Photo Capture ("open camera", "take photo")
///   - QR & Barcode Scanner ("scan qr code", "read barcode")
///   - OCR & Document Scanner ("scan text", "ocr document")
///   - Face Detection ("detect faces")
///   - Object Detection ("detect objects")
class CameraVisionModule implements IActionModule {
  @override
  String get moduleId => 'camera_vision';

  @override
  String getDescription() =>
      'Camera Vision Platform supporting photo capture, QR scanner, OCR, face and object detection.';

  @override
  ModuleCapability get capability => ModuleCapability(
        name: moduleId,
        description: getDescription(),
        supportedCommands: const [
          'open camera',
          'take photo',
          'scan qr code',
          'scan document',
          'read text',
          'detect faces',
          'detect objects',
        ],
      );

  @override
  bool canHandle(String input) {
    final lower = input.toLowerCase().trim();
    return lower.contains('camera') ||
        lower.contains('photo') ||
        lower.contains('scan qr') ||
        lower.contains('scan document') ||
        lower.contains('read text') ||
        lower.contains('ocr') ||
        lower.contains('detect faces') ||
        lower.contains('detect objects');
  }

  @override
  Future<CommandResult> execute(String input, Map<String, dynamic> params) async {
    final lower = input.toLowerCase().trim();

    String? detectorId;
    if (lower.contains('qr') || lower.contains('barcode')) {
      detectorId = 'qr_barcode';
    } else if (lower.contains('document') || lower.contains('ocr') || lower.contains('read text')) {
      detectorId = 'ocr_text';
    } else if (lower.contains('face')) {
      detectorId = 'face_detection';
    } else if (lower.contains('object')) {
      detectorId = 'object_detection';
    }

    FridayLogger.log(LogCategory.action, 'CameraVisionModule: executing for detector = $detectorId');

    final results = await CameraManager.instance.captureAndAnalyze(targetDetectorId: detectorId);

    if (results.isEmpty) {
      return const ActionError(
        userFriendlyMessage: 'Camera permission denied or camera hardware unavailable.',
      );
    }

    final primary = results.first;
    final speech = 'Vision analysis complete: ${primary.textResult}';

    EventBus.instance.fire(CommandExecutedEvent(
      moduleId: moduleId,
      success: true,
      speechResponse: speech,
    ));

    return ActionSuccess(
      speechResponse: speech,
      data: {'detector': primary.detectorId, 'result': primary.textResult},
    );
  }

  @override
  void dispose() {
    CameraManager.instance.dispose();
  }
}
