import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path/path.dart' as p;

import 'package:demixr_app/helpers/onnx/executorch_demixing_engine.dart';

/// Verifies the resident-model warm-up: the first warmUp pays the CoreML
/// compile (~10 s Mac / ~20 s iPhone); the second reuses the resident model and
/// is ~instant. That's what keeps the first demix unstalled after download.
///
///   flutter test integration_test/coreml_cache_probe_test.dart -d macos
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'warmUp compiles once, then reuses the resident model',
    (tester) async {
      final home = Platform.environment['HOME'] ?? '';
      final corePath = p.join(
        home,
        'Downloads',
        'demixr_test',
        'core_coreml.pte',
      );
      if (!File(corePath).existsSync()) {
        markTestSkipped('missing $corePath');
        return;
      }

      final sw1 = Stopwatch()..start();
      await ExecuTorchDemixingEngine.warmUp(corePath);
      sw1.stop();

      final sw2 = Stopwatch()..start();
      await ExecuTorchDemixingEngine.warmUp(corePath);
      sw2.stop();

      await ExecuTorchDemixingEngine.disposeCache();

      // ignore: avoid_print
      print(
        'WARMUP: first=${sw1.elapsedMilliseconds}ms '
        'reuse=${sw2.elapsedMilliseconds}ms',
      );
      expect(
        sw2.elapsedMilliseconds,
        lessThan(sw1.elapsedMilliseconds ~/ 5),
        reason: 'resident model should be reused, not recompiled',
      );
    },
    timeout: const Timeout(Duration(minutes: 5)),
  );
}
