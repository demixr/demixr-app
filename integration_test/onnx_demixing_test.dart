import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_onnxruntime/flutter_onnxruntime.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'package:demixr_app/helpers/demixing_helper.dart';
import 'package:demixr_app/helpers/onnx/demucs_config.dart';
import 'package:demixr_app/helpers/onnx/onnx_demixing_engine.dart';
import 'package:demixr_app/models/song.dart';

/// End-to-end test of the cross-platform ONNX demixing engine.
///
/// Reads a model + fixture staged under `~/Downloads/demixr_test/` (an
/// app-sandbox-accessible location on macOS) and verifies the engine produces
/// the 4 expected stem WAVs, then checks numerical parity against reference
/// stems produced by the `demucs-onnx` Python package (CPU, fp32 model).
///
/// Stage with:
///   ~/Downloads/demixr_test/htdemucs.onnx
///   ~/Downloads/demixr_test/test_clip.wav
///   ~/Downloads/demixr_test/ref_out/{vocals,drums,bass,other}.wav
/// then run: flutter test integration_test/onnx_demixing_test.dart -d macos
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'htdemucs ONNX engine produces 4 parity-matching stems',
    (tester) async {
      // Fixtures live under ~/Downloads/demixr_test on desktop, or the app's
      // external files dir on Android (push there with `adb push`).
      final fixtures = await _fixturesDir();
      // The fp16 model is named differently; accept either.
      var modelPath = p.join(fixtures, 'htdemucs.onnx');
      if (!File(modelPath).existsSync()) {
        modelPath = p.join(fixtures, 'htdemucs_fp16weights.onnx');
      }
      final inputPath = p.join(fixtures, 'test_clip.wav');
      final refDir = p.join(fixtures, 'ref_out');

      if (!File(modelPath).existsSync() || !File(inputPath).existsSync()) {
        markTestSkipped('Fixtures missing under $fixtures');
        return;
      }

      final outDir = p.join((await getTemporaryDirectory()).path, 'onnx_out');
      await Directory(outDir).create(recursive: true);

      final engine = OnnxDemixingEngine();
      var lastProgress = 0.0;
      final stopwatch = Stopwatch()..start();
      final stems = await engine.separate(
        modelPath: modelPath,
        inputPath: inputPath,
        outputDir: outDir,
        sources: DemucsConfig.sources4,
        onProgress: (p) => lastProgress = p,
        providerOverride: [
          OrtProvider.CPU,
        ], // deterministic parity vs reference
      );
      stopwatch.stop();
      // ignore: avoid_print
      print('ONNX demix (CPU) took ${stopwatch.elapsedMilliseconds} ms');

      // Contract: exactly the 4 expected stems.
      expect(stems.keys.toSet(), {'vocals', 'drums', 'bass', 'other'});
      expect(lastProgress, closeTo(1.0, 1e-9));

      for (final stem in stems.keys) {
        final samples = _readWav16(stems[stem]!);
        expect(samples.isNotEmpty, isTrue, reason: '$stem is empty');

        final refFile = File(p.join(refDir, '$stem.wav'));
        if (!refFile.existsSync()) continue;
        final ref = _readWav16(refFile.path);

        // Lengths should match (same overlap-add scheme, same input length).
        expect(
          (samples.length - ref.length).abs(),
          lessThan(DemucsConfig.channels),
          reason: '$stem length ${samples.length} vs ref ${ref.length}',
        );

        final n = min(samples.length, ref.length);
        var maxDiff = 0;
        var sumSq = 0.0;
        for (var i = 0; i < n; i++) {
          final d = (samples[i] - ref[i]).abs();
          if (d > maxDiff) maxDiff = d;
          sumSq += d * d.toDouble();
        }
        final rms = sqrt(sumSq / n);
        // ignore: avoid_print
        print(
          '$stem parity: maxDiff=$maxDiff LSB, rms=${rms.toStringAsFixed(2)} LSB',
        );

        // Both run the same fp32 graph on CPU; allow a few LSB for int16 rounding
        // (reference truncates, we round) and float op-ordering.
        expect(maxDiff, lessThan(8), reason: '$stem max diff too large');
        expect(rms, lessThan(1.0), reason: '$stem rms diff too large');
      }
    },
    timeout: const Timeout(Duration(minutes: 5)),
  );

  testWidgets(
    'htdemucs_6s ONNX engine produces 6 parity-matching stems',
    (tester) async {
      final fixtures = await _fixturesDir();
      final modelPath = p.join(fixtures, 'htdemucs_6s.onnx');
      final inputPath = p.join(fixtures, 'test_clip.wav');
      final refDir = p.join(fixtures, 'ref_out_6s');
      if (!File(modelPath).existsSync() || !File(inputPath).existsSync()) {
        markTestSkipped('6-stem fixtures missing under $fixtures');
        return;
      }

      final outDir = p.join(
        (await getTemporaryDirectory()).path,
        'onnx_out_6s',
      );
      await Directory(outDir).create(recursive: true);

      final stems = await OnnxDemixingEngine().separate(
        modelPath: modelPath,
        inputPath: inputPath,
        outputDir: outDir,
        sources: DemucsConfig.sources6,
        providerOverride: [OrtProvider.CPU],
      );

      expect(stems.keys.toSet(), {
        'vocals',
        'drums',
        'bass',
        'other',
        'guitar',
        'piano',
      });

      for (final stem in stems.keys) {
        final samples = _readWav16(stems[stem]!);
        expect(samples.isNotEmpty, isTrue, reason: '$stem is empty');
        final refFile = File(p.join(refDir, '$stem.wav'));
        if (!refFile.existsSync()) continue;
        final ref = _readWav16(refFile.path);
        final n = min(samples.length, ref.length);
        var maxDiff = 0;
        for (var i = 0; i < n; i++) {
          final d = (samples[i] - ref[i]).abs();
          if (d > maxDiff) maxDiff = d;
        }
        // ignore: avoid_print
        print('6s $stem parity: maxDiff=$maxDiff LSB');
        expect(maxDiff, lessThan(8), reason: '$stem max diff too large');
      }
    },
    timeout: const Timeout(Duration(minutes: 5)),
  );

  // Exercises the real dispatch path that broke on macOS: DemixingHelper must
  // route the 'htdemucs' model to the ONNX engine (not the native channel).
  testWidgets(
    'DemixingHelper routes htdemucs to the ONNX engine',
    (tester) async {
      final fixtures = await _fixturesDir();
      var modelPath = p.join(fixtures, 'htdemucs.onnx');
      if (!File(modelPath).existsSync()) {
        modelPath = p.join(fixtures, 'htdemucs_fp16weights.onnx');
      }
      final inputPath = p.join(fixtures, 'test_clip.wav');
      if (!File(modelPath).existsSync() || !File(inputPath).existsSync()) {
        markTestSkipped('Fixtures missing under $fixtures');
        return;
      }

      final song = Song(
        title: 'test',
        artists: const ['test'],
        path: inputPath,
        duration: Duration.zero,
      );
      final unmixed = await DemixingHelper().separate(
        song,
        modelPath,
        'htdemucs',
      );

      for (final path in [
        unmixed.vocals,
        unmixed.drums,
        unmixed.bass,
        unmixed.other,
      ]) {
        expect(File(path).existsSync(), isTrue, reason: '$path missing');
        expect(File(path).lengthSync(), greaterThan(44), reason: '$path empty');
      }
    },
    timeout: const Timeout(Duration(minutes: 5)),
  );
}

/// Resolves the directory holding the staged model + fixtures per platform.
Future<String> _fixturesDir() async {
  if (Platform.isAndroid) {
    final dir = await getExternalStorageDirectory();
    return p.join(dir!.path, 'demixr_test');
  }
  final home = Platform.environment['HOME'] ?? '';
  return p.join(home, 'Downloads', 'demixr_test');
}

/// Reads a 16-bit PCM WAV (canonical 44-byte header) into interleaved samples.
Int16List _readWav16(String path) {
  final bytes = File(path).readAsBytesSync();
  const headerSize = 44;
  final dataLen = bytes.length - headerSize;
  return bytes.buffer.asInt16List(headerSize, dataLen ~/ 2);
}
