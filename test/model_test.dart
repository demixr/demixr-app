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

    test('ONNX models are cross-platform with a single .onnx', () {
      for (final m in [Models.htdemucsOnnx, Models.htdemucs6s]) {
        expect(m.engine, DemixingEngine.onnx);
        expect(m.fileExtension, '.onnx');
        expect(m.onnxUrl, endsWith('.onnx'));
        // ONNX runs everywhere, so it always resolves a download URL.
        expect(m.downloadUrl, equals(m.onnxUrl));
        expect(m.isSupportedOnCurrentPlatform, isTrue);
      }
    });

    test('htdemucs_6s produces 6 stems, others 4', () {
      expect(Models.htdemucs6s.stems.length, 6);
      expect(Models.htdemucs.stems.length, 4);
      expect(Models.htdemucsOnnx.stems.length, 4);
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
