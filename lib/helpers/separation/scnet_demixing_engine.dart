import 'dart:typed_data';

import 'package:executorch_flutter/executorch_flutter.dart';
import 'package:flutter_onnxruntime/flutter_onnxruntime.dart';
import 'package:path/path.dart' as p;

import '../../models/exceptions/demixing_exception.dart';
import '../../models/model.dart';
import 'audio_io.dart';
import 'scnet_config.dart';
import 'scnet_spectral_transform.dart';

/// End-to-end SCNet pipeline shared by its ONNX CPU and ExecuTorch Vulkan
/// artifacts. Audio framing, spectral conversion, and overlap-add live here;
/// only the small spectral-core invocation changes between runtimes.
class ScnetDemixingEngine {
  final ScnetSpectralTransform _spectral = ScnetSpectralTransform();

  static ExecuTorchModel? _executorchModel;
  static String? _executorchPath;

  static Future<ExecuTorchModel> _loadExecuTorch(String path) async {
    if (_executorchPath == path && _executorchModel != null) {
      return _executorchModel!;
    }
    await _executorchModel?.dispose();
    _executorchModel = await ExecuTorchModel.load(path);
    _executorchPath = path;
    return _executorchModel!;
  }

  static Future<void> warmUp(String path) async => _loadExecuTorch(path);

  Future<Map<String, String>> separate({
    required String modelPath,
    required DemixingEngine engine,
    required String inputPath,
    required String outputDir,
    required List<String> sources,
    void Function(double progress)? onProgress,
  }) async {
    final channels = await decodeToFloatPcm(
      inputPath,
      sampleRate: ScnetConfig.sampleRate,
      channels: ScnetConfig.channels,
    );
    if (channels[0].isEmpty) {
      throw DemixingException('Decoded audio is empty');
    }

    OrtSession? onnxSession;
    ExecuTorchModel? executorchModel;
    if (engine == DemixingEngine.onnx) {
      onnxSession = await OnnxRuntime().createSession(
        modelPath,
        options: OrtSessionOptions(
          providers: [OrtProvider.CPU],
          graphOptimizationLevel: OrtGraphOptimizationLevel.all,
          useArena: false,
        ),
      );
    } else {
      executorchModel = await _loadExecuTorch(modelPath);
    }

    try {
      return await _overlapAdd(
        input: channels,
        outputDir: outputDir,
        sources: sources,
        onProgress: onProgress,
        infer: (input) => onnxSession != null
            ? _inferOnnx(onnxSession, input)
            : _inferExecuTorch(executorchModel!, input),
      );
    } finally {
      await onnxSession?.close();
    }
  }

  Future<Float32List> _inferOnnx(
    OrtSession session,
    ScnetSpectrum spectrum,
  ) async {
    final input = await OrtValue.fromList(spectrum.values, const [
      1,
      4,
      ScnetConfig.bins,
      ScnetConfig.frames,
    ]);
    try {
      final outputs = await session.run({ScnetConfig.inputName: input});
      final output = outputs[ScnetConfig.outputName];
      if (output == null) {
        throw DemixingException('SCNet produced no stems_spec output');
      }
      try {
        final raw = await output.asFlattenedList();
        final values = raw is Float32List
            ? raw
            : Float32List.fromList(
                raw.map((value) => (value as num).toDouble()).toList(),
              );
        return _spectral.inverse(values, spectrum.mean, spectrum.std);
      } finally {
        await output.dispose();
      }
    } finally {
      await input.dispose();
    }
  }

  Future<Float32List> _inferExecuTorch(
    ExecuTorchModel model,
    ScnetSpectrum spectrum,
  ) async {
    final input = ExecutorchManager.instance.createTensorData(
      shape: const [1, 4, ScnetConfig.bins, ScnetConfig.frames],
      dataType: TensorType.float32,
      data: spectrum.values,
    );
    final outputs = await model.forward([input]);
    if (outputs.isEmpty) throw DemixingException('SCNet produced no output');
    final tensor = outputs.first;
    final values = Float32List.view(
      tensor.data.buffer,
      tensor.data.offsetInBytes,
      tensor.data.lengthInBytes ~/ 4,
    );
    return _spectral.inverse(values, spectrum.mean, spectrum.std);
  }

  Future<Map<String, String>> _overlapAdd({
    required List<Float32List> input,
    required String outputDir,
    required List<String> sources,
    required Future<Float32List> Function(ScnetSpectrum input) infer,
    void Function(double progress)? onProgress,
  }) async {
    const segment = ScnetConfig.segment;
    const stride = ScnetConfig.stride;
    const channels = ScnetConfig.channels;
    final totalFrames = input[0].length;
    final chunks = ((totalFrames + stride - 1) ~/ stride).clamp(1, 1 << 30);
    final window = ScnetConfig.buildTransitionWindow();
    final writers = <String, WavWriter>{};
    final paths = <String, String>{};
    for (final source in sources) {
      final path = p.join(outputDir, '$source.wav');
      writers[source] = await WavWriter.create(
        path,
        sampleRate: ScnetConfig.sampleRate,
        channels: channels,
        totalFrames: totalFrames,
      );
      paths[source] = path;
    }

    final accumulators = {
      for (final source in sources)
        source: List.generate(channels, (_) => Float32List(segment)),
    };
    final weights = Float32List(segment);
    final waveform = Float32List(channels * segment);
    var base = 0;
    try {
      for (var chunk = 0; chunk < chunks; chunk++) {
        final start = chunk * stride;
        final chunkLength = (totalFrames - start).clamp(0, segment);
        waveform.fillRange(0, waveform.length, 0);
        for (var channel = 0; channel < channels; channel++) {
          waveform.setRange(
            channel * segment,
            channel * segment + chunkLength,
            input[channel],
            start,
          );
        }
        final stems = await infer(_spectral.forward(waveform));
        for (var source = 0; source < sources.length; source++) {
          for (var channel = 0; channel < channels; channel++) {
            final destination = accumulators[sources[source]]![channel];
            final sourceBase = (source * channels + channel) * segment;
            for (var i = 0; i < chunkLength; i++) {
              destination[i] += stems[sourceBase + i] * window[i];
            }
          }
        }
        for (var i = 0; i < chunkLength; i++) {
          weights[i] += window[i];
        }

        final last = chunk == chunks - 1;
        final flushEnd = last ? totalFrames : (chunk + 1) * stride;
        final flushCount = flushEnd - base;
        for (var i = 0; i < flushCount; i++) {
          final weight = weights[i].clamp(1e-8, double.infinity);
          for (final source in sources) {
            for (var channel = 0; channel < channels; channel++) {
              accumulators[source]![channel][i] /= weight;
            }
          }
        }
        for (final source in sources) {
          writers[source]!.addFrames(accumulators[source]!, 0, flushCount);
        }
        if (!last) {
          final keep = segment - flushCount;
          for (final source in sources) {
            for (final buffer in accumulators[source]!) {
              buffer.setRange(0, keep, buffer, flushCount);
              buffer.fillRange(keep, segment, 0);
            }
          }
          weights.setRange(0, keep, weights, flushCount);
          weights.fillRange(keep, segment, 0);
          base += flushCount;
        }
        onProgress?.call((chunk + 1) / chunks);
      }
    } finally {
      for (final writer in writers.values) {
        await writer.close();
      }
    }
    return paths;
  }
}
