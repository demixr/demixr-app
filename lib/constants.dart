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
  static const openUnmixInfosUrl = 'https://sigsep.github.io/open-unmix/';

  /// htdemucs (Demucs v4), 4-stem, exported to a self-contained ONNX graph.
  /// Cross-platform (Android/iOS/macOS) via ONNX Runtime. The `fp16weights`
  /// variant is ~half the download of fp32 and numerically identical at
  /// runtime (max abs diff ~6e-5).
  static const htdemucs = Model(
    name: 'htdemucs',
    description:
        'Hybrid Transformer Demucs (Demucs v4).\nState-of-the-art quality, runs on all platforms.\n(158 MB)',
    url:
        'https://huggingface.co/StemSplitio/htdemucs-onnx/resolve/main/htdemucs_fp16weights.onnx',
    isDefault: true,
    fileExtension: '.onnx',
    engine: ModelEngine.onnx,
  );

  /// htdemucs_6s — same engine as [htdemucs] but 6 stems (adds guitar + piano).
  static const htdemucs6s = Model(
    name: 'htdemucs_6s',
    description:
        '6-stem Demucs v4: vocals, drums, bass, other, guitar, piano.\nRuns on all platforms, a bit slower than 4-stem.\n(130 MB)',
    url:
        'https://huggingface.co/StemSplitio/htdemucs-6s-onnx/resolve/main/htdemucs_6s_fp16weights.onnx',
    fileExtension: '.onnx',
    engine: ModelEngine.onnx,
    stems: ['vocals', 'drums', 'bass', 'other', 'guitar', 'piano'],
  );

  static const umxhq = Model(
    name: 'umxhq',
    description:
        'Model trained on the MUSDB18-HQ dataset.\nFaster separation (~ length of the song).\n(140 MB)',
    url:
        'https://github.com/demixr/openunmix-torchscript/releases/latest/download/umxhq.ptl',
  );
  static const umxl = Model(
    name: 'umxl',
    description:
        'Model trained on extra data. Longer separation, but improved performance.\n(290 MB)',
    url:
        'https://github.com/demixr/openunmix-torchscript/releases/latest/download/umxl.ptl',
  );

  static Model fromName(String name) {
    if (name == htdemucs.name) return htdemucs;
    if (name == htdemucs6s.name) return htdemucs6s;
    if (name == umxhq.name) return umxhq;
    if (name == umxl.name) return umxl;

    throw ArgumentError('Models: The given model name does not exist');
  }

  static const List<Model> all = [
    Models.htdemucs,
    Models.htdemucs6s,
    Models.umxhq,
    Models.umxl,
  ];

  /// Models whose engine is usable on the current platform (ONNX everywhere,
  /// OpenUnmix only on Android).
  static List<Model> get available =>
      all.where((model) => model.isSupportedOnCurrentPlatform).toList();
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

class PlatformChannels {
  static const demixing = 'demixing';
  static const demixingProgress = 'demixing/progress';
}
