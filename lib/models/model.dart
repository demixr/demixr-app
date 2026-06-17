import 'dart:io' show Platform;

/// The inference engine a [Model] runs on.
///
/// - [openUnmix]: legacy OpenUnmix TorchScript (`.ptl`) via the native Android
///   PyTorch-Lite engine. Android-only.
/// - [onnx]: htdemucs ONNX via ONNX Runtime. Cross-platform (Android/iOS/macOS).
enum ModelEngine { openUnmix, onnx }

class Model {
  final String name;
  final String description;
  final String url;
  final bool isDefault;

  /// File extension used for the locally-downloaded model file.
  final String fileExtension;

  /// Inference engine this model runs on.
  final ModelEngine engine;

  const Model({
    required this.name,
    required this.description,
    required this.url,
    this.isDefault = false,
    this.fileExtension = '.plt',
    this.engine = ModelEngine.openUnmix,
  });

  bool get isOnnx => engine == ModelEngine.onnx;

  /// Whether this model's inference engine can run on the current platform.
  ///
  /// The OpenUnmix engine is a native Android-only plugin; the ONNX engine
  /// runs on every platform. Used to hide unusable models in the UI and to
  /// avoid dispatching to an engine that doesn't exist on the host.
  bool get isSupportedOnCurrentPlatform =>
      engine == ModelEngine.onnx || Platform.isAndroid;
}
