import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_onnxruntime/flutter_onnxruntime.dart';
import 'package:path/path.dart' as p;

import '../../models/exceptions/demixing_exception.dart';
import 'audio_io.dart';
import 'demucs_config.dart';

/// Cross-platform demixing engine backed by ONNX Runtime.
///
/// Loads an htdemucs ONNX model (self-contained STFT/iSTFT in-graph) and
/// produces the 4 stem WAV files (`vocals/drums/bass/other`, 44.1 kHz, 16-bit,
/// stereo) the rest of the app expects. The chunked overlap-add scheme and
/// triangular window match the reference `demucs-onnx` implementation so the
/// output is numerically equivalent.
///
/// Memory is bounded to roughly one segment: stems are streamed to disk as the
/// overlap-add finalizes each region, rather than accumulating the whole song.
class OnnxDemixingEngine {
  /// Runs separation of [inputPath] using the model at [modelPath], writing
  /// `<stem>.wav` files into [outputDir]. Returns a map of stem name to path.
  ///
  /// [onProgress] is called with a 0..1 ratio after each segment.
  Future<Map<String, String>> separate({
    required String modelPath,
    required String inputPath,
    required String outputDir,
    required List<String> sources,
    void Function(double progress)? onProgress,
    List<OrtProvider>? providerOverride,
  }) async {
    final session = await _createSession(modelPath, providerOverride);

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
        session: session,
        input: channels,
        totalFrames: totalFrames,
        outputDir: outputDir,
        sources: sources,
        onProgress: onProgress,
      );
    } finally {
      await session.close();
    }
  }

  /// Creates a session with the platform's preferred execution provider,
  /// falling back to CPU if the accelerated provider fails to initialize
  /// (e.g. a CoreML graph-compile failure on a transformer-heavy model).
  Future<OrtSession> _createSession(
    String modelPath,
    List<OrtProvider>? providerOverride,
  ) async {
    final ort = OnnxRuntime();
    final available = await ort.getAvailableProviders();
    final providers =
        providerOverride ??
        DemucsConfig.preferredProviders(Platform.operatingSystem, available);
    // Disable graph optimization: ORT's default (ALL) constant-folds htdemucs's
    // in-graph STFT into huge tensors, peaking ~5GB and OOM-killing mobile.
    // Disabling it roughly halves peak RSS (~2.2GB) for a small speed cost.
    const optLevel = OrtGraphOptimizationLevel.disableAll;
    try {
      return await ort.createSession(
        modelPath,
        options: OrtSessionOptions(
          providers: providers,
          graphOptimizationLevel: optLevel,
        ),
      );
    } catch (e) {
      debugPrint('ONNX: provider $providers failed ($e); falling back to CPU');
      return await ort.createSession(
        modelPath,
        options: OrtSessionOptions(
          providers: [OrtProvider.CPU],
          graphOptimizationLevel: optLevel,
        ),
      );
    }
  }

  Future<Map<String, String>> _runOverlapAdd({
    required OrtSession session,
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

    // Open one streaming WAV writer per stem.
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

    // Live accumulators, sized to one segment. `base` is the absolute sample
    // index of element 0; by construction it always equals the chunk start.
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

        // Build the [1, 2, segment] input tensor (channel-major), zero-padded.
        for (var c = 0; c < nChannels; c++) {
          final src = input[c];
          final off = c * segment;
          for (var k = 0; k < segment; k++) {
            inputBuf[off + k] = k < chunkLen ? src[start + k] : 0.0;
          }
        }

        final inputValue = await OrtValue.fromList(inputBuf, [
          1,
          nChannels,
          segment,
        ]);
        final stems = await _infer(session, inputValue);
        await inputValue.dispose();

        // Overlap-add the windowed model output into the live accumulators.
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

        // Finalize every sample no later chunk will touch and flush to disk.
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
          // Shift the unfinalized tail back to the front and zero the rest.
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
    }

    return paths;
  }

  /// Runs one segment through the model and returns the flattened `[1,4,2,N]`
  /// output as a [Float32List].
  Future<Float32List> _infer(OrtSession session, OrtValue input) async {
    final outputs = await session.run({DemucsConfig.inputName: input});
    final value = outputs[DemucsConfig.outputName];
    if (value == null) {
      throw DemixingException('Model produced no "stems" output');
    }
    try {
      final raw = await value.asFlattenedList();
      if (raw is Float32List) return raw;
      final out = Float32List(raw.length);
      for (var i = 0; i < raw.length; i++) {
        out[i] = (raw[i] as num).toDouble();
      }
      return out;
    } finally {
      await value.dispose();
    }
  }
}
