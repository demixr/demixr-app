import 'package:executorch_flutter/executorch_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

import '../../models/exceptions/demixing_exception.dart';
import 'audio_io.dart';
import 'demucs_config.dart';
import 'istft.dart';

/// GPU-accelerated demixing engine backed by ExecuTorch.
///
/// The htdemucs network proper runs in one ExecuTorch program (the CoreML
/// delegate caps tensors at rank 5, so the rank-6 mask + iSTFT can't live in
/// the GPU graph):
///  - **core** `.pte` — `mix [1,2,N] -> (pre-mask spec, time)`, includes the
///    in-graph conv STFT. Lowered to CoreML on Apple / Vulkan or XNNPACK on
///    Android (the backend is baked into the `.pte` at export time).
///  - the mask + inverse STFT run in Dart via [Istft] (an O(N log N) FFT). An
///    earlier XNNPACK post `.pte` did this with a dense-DFT `ConvTranspose1d`
///    and was the ~1.75 s/chunk bottleneck; the FFT cuts it ~50-100×.
///
/// Reuses the same FFmpeg decode, streaming 16-bit WAV writer, and chunked
/// triangular-window overlap-add as [OnnxDemixingEngine], so output is the
/// same 4 (or 6) stem WAVs the rest of the app expects.
class ExecuTorchDemixingEngine {
  final Istft _istft = Istft();

  /// Runs separation of [inputPath] using the core [corePath] `.pte`, writing
  /// `<stem>.wav` into [outputDir]. Returns stem name -> path.
  Future<Map<String, String>> separate({
    required String corePath,
    required String inputPath,
    required String outputDir,
    required List<String> sources,
    void Function(double progress)? onProgress,
  }) async {
    final core = await ExecuTorchModel.load(corePath);

    try {
      final channels = await decodeToFloatPcm(
        inputPath,
        sampleRate: DemucsConfig.sampleRate,
        channels: DemucsConfig.channels,
      );
      final totalFrames = channels[0].length;
      if (totalFrames == 0) {
        throw DemixingException('Decoded audio is empty');
      }
      return await _runOverlapAdd(
        core: core,
        input: channels,
        totalFrames: totalFrames,
        outputDir: outputDir,
        sources: sources,
        onProgress: onProgress,
      );
    } finally {
      await core.dispose();
    }
  }

  // Per-run timing accumulators (ms), for profiling.
  double _coreMs = 0, _istftMs = 0, _marshalMs = 0;

  /// Runs one fixed-length segment through core -> Dart iSTFT and returns the
  /// flattened `[1, S, 2, segment]` stems as a [Float32List].
  Future<Float32List> _infer(
    ExecuTorchModel core,
    Float32List mixBuf,
    int sources,
  ) async {
    const segment = DemucsConfig.segment;
    const nChannels = DemucsConfig.channels;
    final sw = Stopwatch()..start();
    final mix = ExecutorchManager.instance.createTensorData(
      shape: [1, nChannels, segment],
      dataType: TensorType.float32,
      data: mixBuf,
    );
    _marshalMs += sw.elapsedMicroseconds / 1000;
    sw.reset();

    final coreOut = await core.forward([mix]);
    _coreMs += sw.elapsedMicroseconds / 1000;
    sw.reset();

    // core emits (spec, time); spec is rank 5, time rank 4.
    final specT = coreOut.firstWhere((t) => t.shape.length == 5);
    final timeT = coreOut.firstWhere((t) => t.shape.length == 4);
    final spec = Float32List.view(
      specT.data.buffer,
      specT.data.offsetInBytes,
      specT.data.lengthInBytes ~/ 4,
    );
    final time = Float32List.view(
      timeT.data.buffer,
      timeT.data.offsetInBytes,
      timeT.data.lengthInBytes ~/ 4,
    );
    final stems = _istft.run(spec, time, sources);
    _istftMs += sw.elapsedMicroseconds / 1000;
    return stems;
  }

  Future<Map<String, String>> _runOverlapAdd({
    required ExecuTorchModel core,
    required List<Float32List> input,
    required int totalFrames,
    required String outputDir,
    required List<String> sources,
    void Function(double progress)? onProgress,
  }) async {
    const segment = DemucsConfig.segment;
    const stride = DemucsConfig.stride;
    const nChannels = DemucsConfig.channels;
    final window = DemucsConfig.buildTransitionWindow();
    final nChunks = ((totalFrames + stride - 1) ~/ stride).clamp(1, 1 << 30);

    final writers = <String, WavWriter>{};
    final paths = <String, String>{};
    for (final stem in sources) {
      final path = p.join(outputDir, '$stem.wav');
      writers[stem] = await WavWriter.create(
        path,
        sampleRate: DemucsConfig.sampleRate,
        channels: nChannels,
        totalFrames: totalFrames,
      );
      paths[stem] = path;
    }

    final acc = {
      for (final stem in sources)
        stem: List.generate(nChannels, (_) => Float32List(segment)),
    };
    final weight = Float32List(segment);
    final inputBuf = Float32List(nChannels * segment);
    var base = 0;

    try {
      for (var i = 0; i < nChunks; i++) {
        final start = i * stride;
        final end = (start + segment) < totalFrames
            ? start + segment
            : totalFrames;
        final chunkLen = end - start;

        for (var c = 0; c < nChannels; c++) {
          final src = input[c];
          final off = c * segment;
          for (var k = 0; k < segment; k++) {
            inputBuf[off + k] = k < chunkLen ? src[start + k] : 0.0;
          }
        }

        final stems = await _infer(core, inputBuf, sources.length);

        for (var row = 0; row < sources.length; row++) {
          final stemAcc = acc[sources[row]]!;
          for (var c = 0; c < nChannels; c++) {
            final dst = stemAcc[c];
            final outBase = (row * nChannels + c) * segment;
            for (var k = 0; k < chunkLen; k++) {
              dst[k] += stems[outBase + k] * window[k];
            }
          }
        }
        for (var k = 0; k < chunkLen; k++) {
          weight[k] += window[k];
        }

        final isLast = i == nChunks - 1;
        final flushEnd = isLast ? totalFrames : (i + 1) * stride;
        final flushCount = flushEnd - base;

        for (var k = 0; k < flushCount; k++) {
          final w = weight[k] < 1e-8 ? 1e-8 : weight[k];
          for (final stem in sources) {
            final stemAcc = acc[stem]!;
            for (var c = 0; c < nChannels; c++) {
              stemAcc[c][k] /= w;
            }
          }
        }
        for (final stem in sources) {
          writers[stem]!.addFrames(acc[stem]!, 0, flushCount);
        }

        if (!isLast) {
          final keep = segment - flushCount;
          for (final stem in sources) {
            for (var c = 0; c < nChannels; c++) {
              final b = acc[stem]![c];
              b.setRange(0, keep, b, flushCount);
              b.fillRange(keep, segment, 0.0);
            }
          }
          weight.setRange(0, keep, weight, flushCount);
          weight.fillRange(keep, segment, 0.0);
          base += flushCount;
        }

        onProgress?.call((i + 1) / nChunks);
      }
    } finally {
      for (final writer in writers.values) {
        await writer.close();
      }
      debugPrint(
        'ExecuTorch timing/$nChunks chunks: core=${_coreMs.round()}ms '
        'istft=${_istftMs.round()}ms marshalIn=${_marshalMs.round()}ms',
      );
    }

    return paths;
  }
}
