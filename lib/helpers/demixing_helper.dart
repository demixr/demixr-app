import 'dart:async';
import 'dart:io';

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

/// Helper handling the source separation, via the cross-platform ONNX
/// (htdemucs) engine that runs in Dart on ONNX Runtime.
///
/// On Apple platforms it will use the GPU-accelerated [ExecuTorchDemixingEngine]
/// (CoreML) instead, when the core `.pte` has been staged locally — see
/// [_stagedExecutorchCore]. This is a temporary dev gate until the `.pte` is
/// hosted + downloaded like the ONNX model (M3).
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
    final outputDir = await getAppTemp();
    final sources = DemucsConfig.sourcesForCount(model.stems.length);
    void onProgress(double p) {
      if (!_progressController.isClosed) _progressController.add(p);
    }

    Map<String, String> separated;
    try {
      final corePte = _stagedExecutorchCore(modelName);
      if (corePte != null) {
        debugPrint('Demixing via ExecuTorch (GPU) core: $corePte');
        separated = await ExecuTorchDemixingEngine().separate(
          corePath: corePte,
          inputPath: song.path,
          outputDir: outputDir,
          sources: sources,
          onProgress: onProgress,
        );
      } else {
        separated = await _engine.separate(
          modelPath: modelPath,
          inputPath: song.path,
          outputDir: outputDir,
          sources: sources,
          onProgress: onProgress,
        );
      }
    } on DemixingException {
      rethrow;
    } catch (e) {
      debugPrint('Demixing failed: $e');
      throw DemixingException('An error occured while demixing');
    }

    checkResult(separated, model);

    return UnmixedSong.fromSeparation(song, separated, modelName: modelName);
  }

  /// Path to a locally-staged ExecuTorch core `.pte` to run on the GPU, or
  /// `null` to fall back to the ONNX/CPU engine.
  ///
  /// TEMPORARY: gated to Apple + the 4-stem htdemucs (the staged `.pte` is that
  /// model) and a hand-placed file under `$HOME/Downloads/demixr_test/`. Once
  /// the `.pte` is hosted and downloaded per platform (M3), this resolves to
  /// the downloaded path instead.
  String? _stagedExecutorchCore(String modelName) {
    if (!(Platform.isMacOS || Platform.isIOS)) return null;
    if (modelName != Models.htdemucs.name) return null;
    final home = Platform.environment['HOME'];
    if (home == null) return null;
    final path = '$home/Downloads/demixr_test/core_coreml.pte';
    return File(path).existsSync() ? path : null;
  }

  /// Check the [separated] result contains exactly the stems [model] produces.
  void checkResult(Map<String, String> separated, Model model) {
    final expected = model.stems.toList()..sort();
    if (!listEquals(separated.keys.toList()..sort(), expected)) {
      throw DemixingException('Invalid demixing result');
    }
  }
}
