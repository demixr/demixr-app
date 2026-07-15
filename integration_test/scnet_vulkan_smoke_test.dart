import 'dart:typed_data';

import 'package:executorch_flutter/executorch_flutter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

/// Device smoke benchmark for the experimental SCNet Vulkan artifact.
///
/// The 50 MiB artifact is intentionally local-only. Stage it at
/// `assets/test_fixtures/scnet_vulkan.pte` and temporarily declare that asset
/// in pubspec.yaml before running this test on Android. It is deliberately not
/// part of production assets, so release builds do not carry a second 50 MiB
/// copy of a model that the setup flow downloads.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'SCNet Vulkan loads and executes one spectral chunk',
    (tester) async {
      await ExecutorchManager.instance.initialize();

      final loadWatch = Stopwatch()..start();
      final model = await ExecuTorchModel.loadFromAsset(
        'assets/test_fixtures/scnet_vulkan.pte',
      );
      loadWatch.stop();

      const shape = [1, 4, 2049, 338];
      final values = Float32List(1 * 4 * 2049 * 338);
      final input = TensorData(
        shape: shape,
        dataType: TensorType.float32,
        data: values.buffer.asUint8List(),
      );

      final runWatch = Stopwatch()..start();
      final outputs = await model.forward([input]);
      runWatch.stop();

      expect(outputs, hasLength(1));
      expect(outputs.single.shape, [1, 4, 4, 2049, 338]);
      final output = Float32List.view(
        outputs.single.data.buffer,
        outputs.single.data.offsetInBytes,
        outputs.single.data.lengthInBytes ~/ Float32List.bytesPerElement,
      );
      expect(output.take(1024).every((value) => value.isFinite), isTrue);

      // ignore: avoid_print
      print(
        'SCNET VULKAN: load=${loadWatch.elapsedMilliseconds}ms '
        'inference=${runWatch.elapsedMilliseconds}ms '
        'output_bytes=${outputs.single.data.lengthInBytes}',
      );
      await model.dispose();
    },
    timeout: const Timeout(Duration(minutes: 15)),
  );
}
