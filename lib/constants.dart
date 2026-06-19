import 'package:demixr_app/models/model.dart';
import 'package:flutter/material.dart';

class ColorPalette {
  static const Color primary = Color.fromRGBO(255, 181, 157, 1);
  static const Color onPrimary = Color.fromRGBO(93, 23, 1, 1);
  static const Color surface = Color.fromRGBO(33, 26, 24, 1);
  static const Color onSurface = Color.fromRGBO(237, 224, 221, 1);
  static const Color surfaceVariant = Color.fromRGBO(83, 67, 63, 1);
  static const Color onSurfaceVariant = Color.fromRGBO(216, 194, 188, 1);
  static const Color tertiary = Color.fromRGBO(245, 226, 167, 1);
  static const Color onTertiary = Color.fromRGBO(58, 47, 4, 1);
  static const Color errorContainer = Color.fromRGBO(147, 0, 6, 1);
  static const Color onError = Color.fromRGBO(255, 218, 212, 1);
  static const Color inverseSurface = Color.fromRGBO(237, 224, 221, 1);
  static const Color inversePrimary = Color.fromRGBO(155, 68, 41, 1);
  static final Color link = Colors.blue.shade300;
  static const List<Color> primaryGradient = [
    Color.fromRGBO(250, 184, 196, 1),
    Color.fromRGBO(89, 86, 233, 1),
  ];
  static const List<Color> primaryFadedGradient = [
    Color.fromRGBO(250, 184, 196, 0.25),
    Color.fromRGBO(89, 86, 233, 0.25),
  ];
  static const List<Color> indicatorColors = [
    ...ColorPalette.primaryGradient,
    ColorPalette.errorContainer,
  ];
}

class Paths {
  static const images = 'assets/images/';
  static const icons = 'assets/icons/';
  static const animations = 'assets/animations/';
}

const songArtistTitleSeparator = '-';

class BoxesNames {
  static const library = 'library';
  static const preferences = 'preferences';
}

class Models {
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

  /// htdemucs_6s — 6 stems (adds guitar + piano), CPU (ONNX).
  static const htdemucs6s = Model(
    name: 'htdemucs_6s',
    description: '6-stem Demucs v4: + guitar, piano. CPU (ONNX).\n(130 MB)',
    engine: DemixingEngine.onnx,
    onnxUrl:
        'https://huggingface.co/StemSplitio/htdemucs-6s-onnx/resolve/main/htdemucs_6s_fp16weights.onnx',
    stems: ['vocals', 'drums', 'bass', 'other', 'guitar', 'piano'],
  );

  static Model fromName(String name) {
    if (name == htdemucs.name) return htdemucs;
    if (name == htdemucsOnnx.name) return htdemucsOnnx;
    if (name == htdemucs6s.name) return htdemucs6s;

    throw ArgumentError('Models: The given model name does not exist');
  }

  static const List<Model> all = [htdemucs, htdemucsOnnx, htdemucs6s];
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
