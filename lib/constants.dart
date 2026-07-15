import 'package:demixr_app/models/model.dart';
import 'package:flutter/material.dart';

class ColorPalette {
  static const Color primary = Color(0xFFFFB59D);
  static const Color onPrimary = Color(0xFF4B190C);
  static const Color surface = Color(0xFF110F14);
  static const Color surfaceContainer = Color(0xFF1A171D);
  static const Color surfaceContainerHigh = Color(0xFF242027);
  static const Color onSurface = Color(0xFFF7EFF1);
  static const Color surfaceVariant = Color(0xFF302B32);
  static const Color onSurfaceVariant = Color(0xFFC8B9BD);
  static const Color outline = Color(0xFF403940);
  static const Color tertiary = Color(0xFFF5E2A7);
  static const Color onTertiary = Color(0xFF3A2F04);
  static const Color errorContainer = Color.fromRGBO(147, 0, 6, 1);
  static const Color onError = Color.fromRGBO(255, 218, 212, 1);
  static const Color inverseSurface = Color(0xFFF4F2FA);
  static const Color inversePrimary = Color(0xFF9B4429);
  static final Color link = Colors.blue.shade300;
  static const List<Color> primaryGradient = [
    Color(0xFFFAB8C4),
    Color(0xFF7770ED),
  ];
  static const List<Color> primaryFadedGradient = [
    Color(0x403B303D),
    Color(0x40323056),
  ];
  static const List<Color> indicatorColors = [
    ...ColorPalette.primaryGradient,
    ColorPalette.errorContainer,
  ];
}

class LayoutBreakpoints {
  /// Width at which screens switch from the stacked mobile composition to
  /// their two-column desktop composition.
  static const double desktop = 760;

  /// Desktop widths below this value use tighter gutters and panel spacing.
  static const double compactDesktop = 1000;
}

class Paths {
  static const images = 'assets/images/';
  static const icons = 'assets/icons/';
  static const animations = 'assets/animations/';
}

const songArtistTitleSeparator = '-';

/// Developer-only build choice. Only this model family is exposed in setup and
/// settings; changing it requires rebuilding the app.
const SeparationArchitecture activeSeparationArchitecture =
    SeparationArchitecture.scnet;

class BoxesNames {
  static const library = 'library';
  static const preferences = 'preferences';
}

class Models {
  static const scnetVulkan = Model(
    name: 'scnet_vulkan',
    displayName: 'SCNet',
    description:
        'SCNet, GPU-accelerated on Android (Vulkan).\nNew separation pipeline.\n(~63 MB)',
    engine: DemixingEngine.executorch,
    architecture: SeparationArchitecture.scnet,
    androidUrl:
        'https://github.com/demixr/scnet-executorch/releases/latest/download/scnet_vulkan.pte',
    stems: ['drums', 'bass', 'other', 'vocals'],
    supportedOperatingSystems: ['android'],
    isDefault: true,
  );

  static const scnetCoreMl = Model(
    name: 'scnet_coreml',
    displayName: 'SCNet',
    description:
        'SCNet, GPU-accelerated (Core ML).\nFastest on Apple devices.\n(~35 MB)',
    engine: DemixingEngine.coreml,
    architecture: SeparationArchitecture.scnet,
    macosUrl:
        'https://github.com/demixr/scnet-executorch/releases/latest/download/scnet_coreml_macos.mlmodelc.zip',
    iosUrl:
        'https://github.com/demixr/scnet-executorch/releases/latest/download/scnet_coreml_ios.mlmodelc.zip',
    stems: ['drums', 'bass', 'other', 'vocals'],
    isDefault: true,
  );

  static const scnetDirectMl = Model(
    name: 'scnet_directml',
    displayName: 'SCNet',
    description:
        'SCNet, GPU-accelerated (DirectML).\nFor Windows GPUs.\n(~52 MB)',
    engine: DemixingEngine.onnx,
    architecture: SeparationArchitecture.scnet,
    onnxUrl:
        'https://github.com/demixr/scnet-executorch/releases/latest/download/scnet_cpu.onnx',
    stems: ['drums', 'bass', 'other', 'vocals'],
    supportedOperatingSystems: ['windows'],
    isDefault: true,
  );

  static const scnetOnnx = Model(
    name: 'scnet_onnx',
    displayName: 'SCNet CPU',
    description: 'SCNet, CPU (ONNX).\nWorks on every device.\n(~63 MB)',
    engine: DemixingEngine.onnx,
    architecture: SeparationArchitecture.scnet,
    onnxUrl:
        'https://github.com/demixr/scnet-executorch/releases/latest/download/scnet_cpu.onnx',
    stems: ['drums', 'bass', 'other', 'vocals'],
  );

  /// htdemucs (Demucs v4), 4-stem, on the **GPU** via ExecuTorch — CoreML on
  /// Apple, Vulkan on Android. Same model weights as [htdemucsOnnx], just a
  /// GPU-accelerated backend (much faster on Apple). The mask + iSTFT run in
  /// Dart, so the `.pte` is the conv+transformer core only.
  static const htdemucs = Model(
    name: 'htdemucs',
    description:
        'Demucs v4, GPU-accelerated (CoreML / Vulkan).\nFastest on supported devices.\n(~270 MB)',
    engine: DemixingEngine.executorch,
    appleUrl:
        'https://github.com/demixr/demucs-executorch/releases/download/v1.0/htdemucs_coreml.pte',
    androidUrl:
        'https://github.com/demixr/demucs-executorch/releases/download/v1.0/htdemucs_vulkan.pte',
    isDefault: true,
  );

  /// Same htdemucs (4-stem) on the **CPU** via ONNX Runtime — one cross-platform
  /// `.onnx`, smaller download, works everywhere.
  static const htdemucsOnnx = Model(
    name: 'htdemucs_onnx',
    description:
        'Demucs v4, CPU (ONNX).\nWorks on every device, smaller download.\n(158 MB)',
    engine: DemixingEngine.onnx,
    onnxUrl:
        'https://huggingface.co/StemSplitio/htdemucs-onnx/resolve/main/htdemucs_fp16weights.onnx',
  );

  // Note: a 6-stem htdemucs variant (adds guitar + piano) was evaluated but
  // excluded — guitar/piano separation quality was poor in initial testing.
  // See README. (The Stem.guitar/piano values + UnmixedSong fields remain for
  // Hive schema compatibility with any previously-saved libraries.)

  static Model fromName(String name) {
    if (name == scnetVulkan.name) return scnetVulkan;
    if (name == scnetCoreMl.name) return scnetCoreMl;
    if (name == scnetDirectMl.name) return scnetDirectMl;
    if (name == scnetOnnx.name) return scnetOnnx;
    if (name == htdemucs.name) return htdemucs;
    if (name == htdemucsOnnx.name) return htdemucsOnnx;

    throw ArgumentError('Models: The given model name does not exist');
  }

  static const List<Model> scnetModels = [
    scnetCoreMl,
    scnetVulkan,
    scnetDirectMl,
    scnetOnnx,
  ];
  static const List<Model> htdemucsModels = [htdemucs, htdemucsOnnx];
  static const List<Model> all =
      activeSeparationArchitecture == SeparationArchitecture.scnet
      ? scnetModels
      : htdemucsModels;

  /// Models that have a downloadable runtime artifact for this platform.
  static List<Model> get supported =>
      all.where((model) => model.isSupportedOnCurrentPlatform).toList();

  /// Prefer the platform's default GPU model when available, otherwise the
  /// cross-platform ONNX model. Windows therefore starts with CPU inference.
  static Model get recommended => supported.firstWhere(
    (model) => model.isDefault,
    orElse: () => activeSeparationArchitecture == SeparationArchitecture.scnet
        ? scnetOnnx
        : htdemucsOnnx,
  );
}

enum Stem { mixture, vocals, drums, bass, other, guitar, piano }

extension StemsName on Stem {
  String get name {
    switch (this) {
      case Stem.mixture:
        return 'Mixture';
      case Stem.vocals:
        return 'Vocals';
      case Stem.drums:
        return 'Drums';
      case Stem.bass:
        return 'Bass';
      case Stem.other:
        return 'Other';
      case Stem.guitar:
        return 'Guitar';
      case Stem.piano:
        return 'Piano';
    }
  }

  String get value => name.toLowerCase();
}

/// Resolves a [Stem] from its lowercase [value] (e.g. 'guitar'). Throws if
/// the name is not a known stem.
Stem stemFromValue(String value) =>
    Stem.values.firstWhere((stem) => stem.value == value);

class Preferences {
  static const model = 'model';
}
