import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'package:demixr_app/helpers/separation/demucs_config.dart';
import 'package:demixr_app/helpers/separation/executorch_demixing_engine.dart';

/// End-to-end test of the ExecuTorch (GPU) engine via executorch_flutter.
///
/// Stage under ~/Downloads/demixr_test/:
///   core_coreml.pte, test_clip.wav, ref_out/{4 stems}.wav
/// Run: flutter test integration_test/executorch_demixing_test.dart -d macos
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'ExecuTorch engine produces 4 stems matching the reference',
    (tester) async {
      final home = Platform.environment['HOME'] ?? '';
      final fix = p.join(home, 'Downloads', 'demixr_test');
      final corePath = p.join(fix, 'core_coreml.pte');
      final inputPath = p.join(fix, 'test_clip.wav');
      if (![corePath, inputPath].every((f) => File(f).existsSync())) {
        markTestSkipped('ExecuTorch fixtures missing under $fix');
        return;
      }

      final outDir = p.join((await getTemporaryDirectory()).path, 'et_out');
      await Directory(outDir).create(recursive: true);

      final sw = Stopwatch()..start();
      final stems = await ExecuTorchDemixingEngine().separate(
        corePath: corePath,
        inputPath: inputPath,
        outputDir: outDir,
        sources: DemucsConfig.sources4,
      );
      sw.stop();
      // ignore: avoid_print
      print('ExecuTorch demix took ${sw.elapsedMilliseconds} ms');

      expect(stems.keys.toSet(), {'vocals', 'drums', 'bass', 'other'});

      // Compare all stems (concatenated) to the demucs-onnx reference. ExecuTorch
      // runs CoreML fp16 vs the fp32 reference, so expect high correlation, not
      // bit-exactness.
      final refDir = p.join(fix, 'ref_out');
      final mine = <int>[];
      final ref = <int>[];
      for (final stem in ['drums', 'bass', 'other', 'vocals']) {
        final samples = _readWav16(stems[stem]!);
        expect(samples.isNotEmpty, isTrue, reason: '$stem empty');
        final refFile = File(p.join(refDir, '$stem.wav'));
        if (!refFile.existsSync()) continue;
        final r = _readWav16(refFile.path);
        final n = min(samples.length, r.length);
        mine.addAll(samples.sublist(0, n));
        ref.addAll(r.sublist(0, n));
      }
      if (ref.isNotEmpty) {
        final corr = _corr(mine, ref);
        // ignore: avoid_print
        print('ExecuTorch vs reference corr=${corr.toStringAsFixed(4)}');
        expect(
          corr,
          greaterThan(0.97),
          reason: 'output diverges from reference',
        );
      }
    },
    timeout: const Timeout(Duration(minutes: 10)),
  );
}

double _corr(List<int> a, List<int> b) {
  final n = a.length;
  var sa = 0.0, sb = 0.0;
  for (var i = 0; i < n; i++) {
    sa += a[i];
    sb += b[i];
  }
  final ma = sa / n, mb = sb / n;
  var cov = 0.0, va = 0.0, vb = 0.0;
  for (var i = 0; i < n; i++) {
    final da = a[i] - ma, db = b[i] - mb;
    cov += da * db;
    va += da * da;
    vb += db * db;
  }
  return cov / (sqrt(va * vb) + 1e-9);
}

Int16List _readWav16(String path) {
  final bytes = File(path).readAsBytesSync();
  return bytes.buffer.asInt16List(44, (bytes.length - 44) ~/ 2);
}
