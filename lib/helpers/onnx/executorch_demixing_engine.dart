import 'package:executorch_flutter/executorch_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

import '../../models/exceptions/demixing_exception.dart';
import 'audio_io.dart';
import 'demucs_config.dart';

/// GPU-accelerated demixing engine backed by ExecuTorch.
///
/// htdemucs is split into two ExecuTorch programs (the CoreML delegate caps
/// tensors at rank 5, so the rank-6 mask + iSTFT can't live in the GPU graph):
///  - **core** `.pte` — `mix [1,2,N] -> (pre-mask spec, time)`, includes the
///    in-graph conv STFT. Lowered to CoreML on Apple / Vulkan or XNNPACK on
///    Android (the backend is baked into the `.pte` at export time).
///  - **post** `.pte` — `(spec, time) -> stems [1,S,2,N]` (mask + iSTFT),
///    XNNPACK/CPU on every platform.
///
/// Reuses the same FFmpeg decode, streaming 16-bit WAV writer, and chunked
/// triangular-window overlap-add as [OnnxDemixingEngine], so output is the
/// same 4 (or 6) stem WAVs the rest of the app expects.
class ExecuTorchDemixingEngine {
  /// Runs separation of [inputPath] using the [corePath] + [postPath] `.pte`s,
  /// writing `<stem>.wav` into [outputDir]. Returns stem name -> path.
  Future<Map<String, String>> separate({
    required String corePath,
    required String postPath,
    required String inputPath,
    required String outputDir,
    required List<String> sources,
    void Function(double progress)? onProgress,
  }) async {
    final core = await ExecuTorchModel.load(corePath);
    final post = await ExecuTorchModel.load(postPath);

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
        post: post,
        input: channels,
        totalFrames: totalFrames,
        outputDir: outputDir,
        sources: sources,
        onProgress: onProgress,
      );
    } finally {
      await core.dispose();
      await post.dispose();
    }
  }

  /// Runs one fixed-length segment through core -> post and returns the
  /// flattened `[1, S, 2, segment]` stems as a [Float32List].
  Future<Float32List> _infer(
    ExecuTorchModel core,
    ExecuTorchModel post,
    Float32List mixBuf,
  ) async {
    const segment = DemucsConfig.segment;
    const nChannels = DemucsConfig.channels;
    final mix = ExecutorchManager.instance.createTensorData(
      shape: [1, nChannels, segment],
      dataType: TensorType.float32,
      data: mixBuf,
    );
    // core: mix -> [spec, time]; those flow straight into post -> [stems].
    final coreOut = await core.forward([mix]);
    final stems = await post.forward(coreOut);
    final flat = TensorUtils.extractFloat32Data(stems.first);
    return flat is Float32List ? flat : Float32List.fromList(flat);
  }

  Future<Map<String, String>> _runOverlapAdd({
    required ExecuTorchModel core,
    required ExecuTorchModel post,
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
        final end =
            (start + segment) < totalFrames ? start + segment : totalFrames;
        final chunkLen = end - start;

        for (var c = 0; c < nChannels; c++) {
          final src = input[c];
          final off = c * segment;
          for (var k = 0; k < segment; k++) {
            inputBuf[off + k] = k < chunkLen ? src[start + k] : 0.0;
          }
        }

        final stems = await _infer(core, post, inputBuf);

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
      debugPrint('ExecuTorch demix wrote ${paths.length} stems');
    }

    return paths;
  }
}
