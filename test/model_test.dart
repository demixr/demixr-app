import 'package:flutter_test/flutter_test.dart';

import 'package:demixr_app/constants.dart';
import 'package:demixr_app/models/model.dart';

void main() {
  group('Model engine + download', () {
    test('GPU htdemucs is ExecuTorch with a .pte and per-platform URLs', () {
      const m = Models.htdemucs;
      expect(m.engine, DemixingEngine.executorch);
      expect(m.fileExtension, '.pte');
      expect(m.isDefault, isTrue);
      expect(m.appleUrl, contains('demucs-executorch'));
      expect(m.appleUrl, endsWith('.pte'));
      expect(m.androidUrl, endsWith('.pte'));
      expect(m.onnxUrl, isNull);
    });

    test('ONNX model is cross-platform with a single .onnx', () {
      const m = Models.htdemucsOnnx;
      expect(m.engine, DemixingEngine.onnx);
      expect(m.fileExtension, '.onnx');
      expect(m.onnxUrl, endsWith('.onnx'));
      // ONNX runs everywhere, so it always resolves a download URL.
      expect(m.downloadUrl, equals(m.onnxUrl));
      expect(m.isSupportedOnCurrentPlatform, isTrue);
    });

    test('all models produce 4 stems (no 6-stem model)', () {
      for (final m in Models.all) {
        expect(m.stems.length, 4);
      }
    });

    test('fromName round-trips every catalog entry; unknown throws', () {
      for (final m in Models.all) {
        expect(Models.fromName(m.name).name, m.name);
      }
      expect(() => Models.fromName('nope'), throwsArgumentError);
    });

    test(
      'GPU model resolves the Apple .pte on this host (macOS test runner)',
      () {
        // The unit-test host is macOS, so the executorch model resolves the
        // CoreML download. (Android resolution is covered on-device.)
        expect(Models.htdemucs.downloadUrl, Models.htdemucs.appleUrl);
      },
    );
  });
}
