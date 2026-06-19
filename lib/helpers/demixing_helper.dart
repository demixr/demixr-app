import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/model.dart';
import '../models/song.dart';
import '../models/unmixed_song.dart';
import '../models/exceptions/demixing_exception.dart';
import 'onnx/demucs_config.dart';
import 'onnx/executorch_demixing_engine.dart';
import 'onnx/onnx_demixing_engine.dart';
import '../utils.dart';
import '../constants.dart';

/// Handles source separation. Routes to one of two engines by the model's
/// [DemixingEngine]: the GPU [ExecuTorchDemixingEngine] (CoreML/Vulkan `.pte`)
/// or the cross-platform CPU [OnnxDemixingEngine] (`.onnx`). Both run the same
/// htdemucs model and share the Dart decode / overlap-add / WAV-writing.
///
/// Exposes a single [progressStream] of doubles in `[0, 1]`.
class DemixingHelper {
  final _progressController = StreamController<double>.broadcast();

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
    final outputDir = await getAppTemp();
    final sources = DemucsConfig.sourcesForCount(model.stems.length);
    void onProgress(double p) {
      if (!_progressController.isClosed) _progressController.add(p);
    }

    Map<String, String> separated;
    try {
      separated = switch (model.engine) {
        DemixingEngine.executorch => await ExecuTorchDemixingEngine().separate(
          corePath: modelPath,
          inputPath: song.path,
          outputDir: outputDir,
          sources: sources,
          onProgress: onProgress,
        ),
        DemixingEngine.onnx => await OnnxDemixingEngine().separate(
          modelPath: modelPath,
          inputPath: song.path,
          outputDir: outputDir,
          sources: sources,
          onProgress: onProgress,
        ),
      };
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
