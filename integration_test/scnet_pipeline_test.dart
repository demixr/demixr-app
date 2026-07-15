import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:demixr_app/helpers/separation/audio_io.dart';
import 'package:demixr_app/helpers/separation/scnet_config.dart';
import 'package:demixr_app/helpers/separation/scnet_demixing_engine.dart';
import 'package:demixr_app/models/model.dart';
import 'package:ffmpeg_kit_extended_flutter/ffmpeg_kit_extended_flutter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

/// Runs the released SCNet core through the complete app pipeline.
///
/// Example:
/// flutter test integration_test/scnet_pipeline_test.dart -d macos \
///   --dart-define=SCNET_MODEL_PATH=/tmp/scnet_cpu.onnx
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'released SCNet model produces four playable stems',
    (tester) async {
      await FFmpegKitExtended.initialize();
      const modelPath = String.fromEnvironment('SCNET_MODEL_PATH');
      if (modelPath.isEmpty || !File(modelPath).existsSync()) {
        markTestSkipped('Set SCNET_MODEL_PATH to the released scnet_cpu.onnx');
        return;
      }

      final directory = await Directory.systemTemp.createTemp('demixr_scnet_');
      addTearDown(() => directory.delete(recursive: true));
      // The macOS native ONNX plugin runs inside the app sandbox and cannot
      // open an arbitrary host /tmp path. Copy the fixture into this test
      // process's sandbox before handing the path to the native session.
      final sandboxedModelPath = '${directory.path}/scnet_cpu.onnx';
      await File(modelPath).copy(sandboxedModelPath);
      final inputPath = '${directory.path}/input.wav';
      final writer = await WavWriter.create(
        inputPath,
        sampleRate: ScnetConfig.sampleRate,
        channels: ScnetConfig.channels,
        totalFrames: ScnetConfig.sampleRate,
      );
      final channels = List.generate(
        ScnetConfig.channels,
        (channel) => Float32List.fromList([
          for (var i = 0; i < ScnetConfig.sampleRate; i++)
            0.1 *
                math.sin(
                  2 *
                      math.pi *
                      (220 + channel * 110) *
                      i /
                      ScnetConfig.sampleRate,
                ),
        ]),
      );
      writer.addFrames(channels, 0, ScnetConfig.sampleRate);
      await writer.close();

      final stems = await ScnetDemixingEngine().separate(
        modelPath: sandboxedModelPath,
        engine: DemixingEngine.onnx,
        inputPath: inputPath,
        outputDir: directory.path,
        sources: ScnetConfig.sourceNames,
      );
      expect(stems.keys, containsAll(ScnetConfig.sourceNames));
      for (final path in stems.values) {
        expect(await File(path).length(), greaterThan(44));
      }
    },
    timeout: const Timeout(Duration(minutes: 5)),
  );
}
