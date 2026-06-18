import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/model.dart';
import '../models/song.dart';
import '../models/unmixed_song.dart';
import '../models/exceptions/demixing_exception.dart';
import 'onnx/demucs_config.dart';
import 'onnx/onnx_demixing_engine.dart';
import '../utils.dart';
import '../constants.dart';

/// Helper handling the source separation, via the cross-platform ONNX
/// (htdemucs) engine that runs in Dart on ONNX Runtime.
///
/// Exposes a single [progressStream] of doubles in `[0, 1]`.
class DemixingHelper {
  final _progressController = StreamController<double>.broadcast();
  final _engine = OnnxDemixingEngine();

  /// The demixing progress stream, values in `[0, 1]`.
  Stream<double> get progressStream => _progressController.stream;

  /// Separates the given [song] into stems using the model at [modelPath].
  /// Throws a [DemixingException] on failure.
  Future<UnmixedSong> separate(
    Song song,
    String modelPath,
    String modelName,
  ) async {
    final model = Models.fromName(modelName);

    Map<String, String> separated;
    try {
      separated = await _engine.separate(
        modelPath: modelPath,
        inputPath: song.path,
        outputDir: await getAppTemp(),
        sources: DemucsConfig.sourcesForCount(model.stems.length),
        onProgress: (p) {
          if (!_progressController.isClosed) _progressController.add(p);
        },
      );
    } on DemixingException {
      rethrow;
    } catch (e) {
      debugPrint('Demixing failed: $e');
      throw DemixingException('An error occured while demixing');
    }

    checkResult(separated, model);

    return UnmixedSong.fromSeparation(song, separated, modelName: modelName);
  }

  /// Check the [separated] result contains exactly the stems [model] produces.
  void checkResult(Map<String, String> separated, Model model) {
    final expected = model.stems.toList()..sort();
    if (!listEquals(separated.keys.toList()..sort(), expected)) {
      throw DemixingException('Invalid demixing result');
    }
  }
}
