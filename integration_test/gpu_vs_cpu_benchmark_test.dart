import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'package:demixr_app/helpers/onnx/demucs_config.dart';
import 'package:demixr_app/helpers/onnx/executorch_demixing_engine.dart';
import 'package:demixr_app/helpers/onnx/onnx_demixing_engine.dart';

/// GPU (ExecuTorch/CoreML) vs CPU (ONNX) benchmark on the same ~4-min input.
///
/// Stage under $HOME/Downloads/demixr_test/:
///   core_coreml.pte, htdemucs_fp16.onnx, bench_4min.wav
/// Run: flutter test integration_test/gpu_vs_cpu_benchmark_test.dart -d macos
///
/// RTF = wall-clock / audio-duration (content-independent, so a tiled clip is
/// representative). Prints both engines + the speedup.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('GPU vs CPU demix RTF', (tester) async {
    final home = Platform.environment['HOME'] ?? '';
    final fix = p.join(home, 'Downloads', 'demixr_test');
    final corePath = p.join(fix, 'core_coreml.pte');
    final onnxPath = p.join(fix, 'htdemucs_fp16.onnx');
    final inputPath = p.join(fix, 'bench_4min.wav');
    for (final f in [corePath, onnxPath, inputPath]) {
      if (!File(f).existsSync()) {
        markTestSkipped('missing fixture: $f');
        return;
      }
    }

    final seconds =
        (File(inputPath).lengthSync() - 44) / (DemucsConfig.sampleRate * 2 * 2);
    final tmp = (await getTemporaryDirectory()).path;

    Future<double> run(
      String label,
      Future<void> Function(String out) body,
    ) async {
      final out = p.join(tmp, label);
      await Directory(out).create(recursive: true);
      final sw = Stopwatch()..start();
      await body(out);
      sw.stop();
      final rtf = (sw.elapsedMilliseconds / 1000.0) / seconds;
      // ignore: avoid_print
      print(
        'BENCH [$label]: ${seconds.toStringAsFixed(0)}s audio in '
        '${(sw.elapsedMilliseconds / 1000.0).toStringAsFixed(1)}s '
        '-> RTF=${rtf.toStringAsFixed(3)}',
      );
      return rtf;
    }

    final gpu = await run('gpu', (out) async {
      await ExecuTorchDemixingEngine().separate(
        corePath: corePath,
        inputPath: inputPath,
        outputDir: out,
        sources: DemucsConfig.sources4,
      );
    });
    final cpu = await run('cpu', (out) async {
      await OnnxDemixingEngine().separate(
        modelPath: onnxPath,
        inputPath: inputPath,
        outputDir: out,
        sources: DemucsConfig.sources4,
      );
    });

    // ignore: avoid_print
    print(
      'BENCH RESULT: GPU RTF=${gpu.toStringAsFixed(3)}  '
      'CPU RTF=${cpu.toStringAsFixed(3)}  '
      'speedup=${(cpu / gpu).toStringAsFixed(2)}x',
    );
  }, timeout: const Timeout(Duration(minutes: 30)));
}
