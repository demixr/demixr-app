import 'dart:io';

/// The inference engine a model runs on.
enum DemixingEngine {
  /// ExecuTorch — GPU-accelerated, per-platform `.pte` (CoreML on Apple,
  /// Vulkan on Android).
  executorch,

  /// ONNX Runtime — cross-platform CPU, a single `.onnx`.
  onnx,

  /// Native Apple Core ML package.
  coreml,
}

/// The signal-processing pipeline surrounding the inference artifact.
enum SeparationArchitecture { htdemucs, scnet }

class Model {
  final String name;
  final String? displayName;
  final String description;
  final bool isDefault;

  /// Which engine runs this model (decides the download + the demixing path).
  final DemixingEngine engine;

  final SeparationArchitecture architecture;

  /// ONNX download (cross-platform). Used when [engine] is [DemixingEngine.onnx].
  final String? onnxUrl;

  /// ExecuTorch `.pte` downloads, per platform. CoreML for Apple, Vulkan for
  /// Android — the model weights are identical, only the backend differs.
  final String? appleUrl;
  final String? macosUrl;
  final String? iosUrl;
  final String? androidUrl;

  /// Ordered stem names this model produces. The order must match the rows of
  /// the model's output tensor. Defaults to the standard 4.
  final List<String> stems;
  final List<String>? supportedOperatingSystems;

  const Model({
    required this.name,
    this.displayName,
    required this.description,
    required this.engine,
    this.architecture = SeparationArchitecture.htdemucs,
    this.isDefault = false,
    this.onnxUrl,
    this.appleUrl,
    this.macosUrl,
    this.iosUrl,
    this.androidUrl,
    this.stems = const ['vocals', 'drums', 'bass', 'other'],
    this.supportedOperatingSystems,
  });

  /// Extension of the locally-downloaded model file.
  String get fileExtension => switch (engine) {
    DemixingEngine.onnx => '.onnx',
    DemixingEngine.executorch => '.pte',
    DemixingEngine.coreml => '.mlmodelc',
  };

  String get downloadFileExtension =>
      engine == DemixingEngine.coreml ? '.mlmodelc.zip' : fileExtension;

  /// The download URL for the current platform, or `null` if this model can't
  /// run here (e.g. an ExecuTorch model with no `.pte` for this platform).
  String? get downloadUrl {
    if (supportedOperatingSystems != null &&
        !supportedOperatingSystems!.contains(Platform.operatingSystem)) {
      return null;
    }
    if (engine == DemixingEngine.onnx) return onnxUrl;
    if (Platform.isMacOS) return macosUrl ?? appleUrl;
    if (Platform.isIOS) return iosUrl ?? appleUrl;
    if (Platform.isAndroid) return androidUrl;
    return null;
  }

  /// Whether this model is runnable on the current platform.
  bool get isSupportedOnCurrentPlatform => downloadUrl != null;
}
