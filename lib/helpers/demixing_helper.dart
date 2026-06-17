import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../models/song.dart';
import '../models/unmixed_song.dart';
import '../models/exceptions/demixing_exception.dart';
import 'onnx/onnx_demixing_engine.dart';
import '../utils.dart';
import '../constants.dart';

/// Helper handling the source separation.
///
/// Two engines sit behind the same [separate] API:
/// - **ONNX** (htdemucs): cross-platform, runs in Dart via ONNX Runtime.
/// - **OpenUnmix** (legacy): Android-only native PyTorch-Lite engine, reached
///   over the `demixing` MethodChannel + `demixing/progress` EventChannel.
///
/// Both feed a single [progressStream] of doubles in `[0, 1]`.
class DemixingHelper {
  static const _methodChannel = MethodChannel(PlatformChannels.demixing);
  static const _eventChannel = EventChannel(PlatformChannels.demixingProgress);

  final _progressController = StreamController<double>.broadcast();
  final _engine = OnnxDemixingEngine();

  /// The demixing progress stream, values in `[0, 1]`.
  Stream<double> get progressStream => _progressController.stream;

  /// Separates the given [song] into the 4 stems using the model at
  /// [modelPath]. Dispatches to the ONNX or the legacy native engine based on
  /// the [modelName]. Throws a [DemixingException] on failure.
  Future<UnmixedSong> separate(
    Song song,
    String modelPath,
    String modelName,
  ) async {
    final model = Models.fromName(modelName);
    final separated = model.isOnnx
        ? await _separateOnnx(song, modelPath)
        : await _separateNative(song, modelPath);

    checkResult(separated);

    return UnmixedSong.fromSong(
      song,
      vocals: separated[Stem.vocals.value]!,
      bass: separated[Stem.bass.value]!,
      drums: separated[Stem.drums.value]!,
      other: separated[Stem.other.value]!,
      modelName: modelName,
    );
  }

  /// Runs the cross-platform ONNX engine.
  Future<Map<String, String>> _separateOnnx(Song song, String modelPath) async {
    try {
      return await _engine.separate(
        modelPath: modelPath,
        inputPath: song.path,
        outputDir: await getAppTemp(),
        onProgress: (p) {
          if (!_progressController.isClosed) _progressController.add(p);
        },
      );
    } on DemixingException {
      rethrow;
    } catch (e) {
      debugPrint('ONNX demixing failed: $e');
      throw DemixingException('An error occured while demixing');
    }
  }

  /// Runs the legacy native (OpenUnmix) engine and forwards its EventChannel
  /// progress into the unified [progressStream].
  Future<Map<String, String>> _separateNative(
    Song song,
    String modelPath,
  ) async {
    if (!Platform.isAndroid) {
      throw DemixingException('This model is only available on Android');
    }

    final subscription = _eventChannel
        .receiveBroadcastStream()
        .cast<double>()
        .listen((p) {
          if (!_progressController.isClosed) _progressController.add(p);
        });

    try {
      final result = await _methodChannel
          .invokeMethod('separate', <String, String>{
            'songPath': song.path,
            'modelPath': modelPath,
            'outputPath': await getAppTemp(),
          });
      return (result as Map).cast<String, String>();
    } on PlatformException {
      throw DemixingException('An error occured while demixing');
    } finally {
      await subscription.cancel();
    }
  }

  /// Check the [separated] result to make sure all stems are present.
  void checkResult(Map<String, String> separated) {
    final stems = [
      Stem.bass.value,
      Stem.drums.value,
      Stem.other.value,
      Stem.vocals.value,
    ];

    if (!listEquals(separated.keys.toList()..sort(), stems..sort())) {
      throw DemixingException('Invalid demixing result');
    }
  }
}
