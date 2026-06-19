import 'dart:io';

/// The inference engine a model runs on.
enum DemixingEngine {
  /// ExecuTorch — GPU-accelerated, per-platform `.pte` (CoreML on Apple,
  /// Vulkan on Android).
  executorch,

  /// ONNX Runtime — cross-platform CPU, a single `.onnx`.
  onnx,
}

class Model {
  final String name;
  final String description;
  final bool isDefault;

  /// Which engine runs this model (decides the download + the demixing path).
  final DemixingEngine engine;

  /// ONNX download (cross-platform). Used when [engine] is [DemixingEngine.onnx].
  final String? onnxUrl;

  /// ExecuTorch `.pte` downloads, per platform. CoreML for Apple, Vulkan for
  /// Android — the model weights are identical, only the backend differs.
  final String? appleUrl;
  final String? androidUrl;

  /// Ordered stem names this model produces. The order must match the rows of
  /// the model's output tensor. Defaults to the standard 4.
  final List<String> stems;

  const Model({
    required this.name,
    required this.description,
    required this.engine,
    this.isDefault = false,
    this.onnxUrl,
    this.appleUrl,
    this.androidUrl,
    this.stems = const ['vocals', 'drums', 'bass', 'other'],
  });

  /// Extension of the locally-downloaded model file.
  String get fileExtension => engine == DemixingEngine.onnx ? '.onnx' : '.pte';

  /// The download URL for the current platform, or `null` if this model can't
  /// run here (e.g. an ExecuTorch model with no `.pte` for this platform).
  String? get downloadUrl {
    if (engine == DemixingEngine.onnx) return onnxUrl;
    if (Platform.isMacOS || Platform.isIOS) return appleUrl;
    if (Platform.isAndroid) return androidUrl;
    return null;
  }

  /// Whether this model is runnable on the current platform.
  bool get isSupportedOnCurrentPlatform => downloadUrl != null;
}
