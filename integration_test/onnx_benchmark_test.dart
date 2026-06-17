import 'dart:io';

import 'package:flutter_onnxruntime/flutter_onnxruntime.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'package:demixr_app/helpers/onnx/onnx_demixing_engine.dart';

/// Benchmarks the htdemucs ONNX engine across execution providers so we can
/// pick the fastest per platform (the accelerator is not assumed — measured).
///
/// Stage `~/Downloads/demixr_test/{htdemucs.onnx,test_clip.wav}` then run:
///   flutter test integration_test/onnx_benchmark_test.dart -d macos
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  final home = Platform.environment['HOME'] ?? '';
  final fixtures = p.join(home, 'Downloads', 'demixr_test');
  final modelPath = p.join(fixtures, 'htdemucs.onnx');
  final inputPath = p.join(fixtures, 'test_clip.wav');

  Future<int> run(List<OrtProvider>? providers, String outName) async {
    final outDir = p.join((await getTemporaryDirectory()).path, outName);
    await Directory(outDir).create(recursive: true);
    final sw = Stopwatch()..start();
    await OnnxDemixingEngine().separate(
      modelPath: modelPath,
      inputPath: inputPath,
      outputDir: outDir,
      providerOverride: providers,
    );
    sw.stop();
    return sw.elapsedMilliseconds;
  }

  testWidgets('benchmark CPU vs available accelerators', (tester) async {
    if (!File(modelPath).existsSync()) {
      markTestSkipped('Fixtures missing under $fixtures');
      return;
    }

    final available = await OnnxRuntime().getAvailableProviders();
    // ignore: avoid_print
    print('available providers: ${available.map((e) => e.name).toList()}');

    final cpuMs = await run([OrtProvider.CPU], 'bench_cpu');
    // ignore: avoid_print
    print('CPU: $cpuMs ms');

    if (available.contains(OrtProvider.CORE_ML)) {
      final mlMs = await run([OrtProvider.CORE_ML, OrtProvider.CPU], 'bench_coreml');
      // ignore: avoid_print
      print('CoreML(+CPU): $mlMs ms (includes graph compile on first run)');
    }
  }, timeout: const Timeout(Duration(minutes: 15)));
}
