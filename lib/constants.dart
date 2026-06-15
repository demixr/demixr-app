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
  static const demucsExecutorchRepoUrl =
      'https://github.com/demixr/demucs-executorch';

  static const fileExtension = '.pte';

  static const htdemucs = Model(
    name: 'htdemucs',
    description:
        'Demucs v4 — SOTA quality separation (SDR ~12.1 vocals).\n'
        '4 stems: vocals, drums, bass, other.\n'
        '~84 MB, GPU accelerated via MPS/CoreML.',
    url:
        'https://github.com/demixr/demucs-executorch/releases/download/v1.0/htdemucs.pte',
    isDefault: true,
  );
  static const htdemucsFt = Model(
    name: 'htdemucs_ft',
    description:
        'Demucs v4 Fine-Tuned — Best quality separation.\n'
        '4 stems: vocals, drums, bass, other.\n'
        '~333 MB, GPU accelerated via MPS/CoreML.',
    url:
        'https://github.com/demixr/demucs-executorch/releases/download/v1.0/htdemucs_ft.pte',
  );
  static const htdemucs6s = Model(
    name: 'htdemucs_6s',
    description:
        'Demucs v4 — 6 stems with piano and guitar.\n'
        '6 stems: vocals, drums, bass, guitar, piano, other.\n'
        '~84 MB, GPU accelerated via MPS/CoreML.',
    url:
        'https://github.com/demixr/demucs-executorch/releases/download/v1.0/htdemucs_6s.pte',
  );

  static Model fromName(String name) {
    if (name == htdemucs.name) return htdemucs;
    if (name == htdemucsFt.name) return htdemucsFt;
    if (name == htdemucs6s.name) return htdemucs6s;

    // Fallback: try old model names for backward compatibility
    if (name == 'umxhq') return htdemucs;
    if (name == 'umxl') return htdemucsFt;

    throw ArgumentError('Models: The given model name does not exist');
  }

  static const List<Model> all = [
    Models.htdemucs,
    Models.htdemucsFt,
    Models.htdemucs6s,
  ];
}

enum Stem {
  mixture,
  vocals,
  drums,
  bass,
  other,
}

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
    }
  }

  String get value => name.toLowerCase();
}

class Preferences {
  static const model = 'model';
}


