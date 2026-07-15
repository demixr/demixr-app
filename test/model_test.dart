import 'dart:io';

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

    test(
      'active catalog exposes SCNet while both families stay resolvable',
      () {
        expect(activeSeparationArchitecture, SeparationArchitecture.scnet);
        expect(Models.all, Models.scnetModels);
        expect(Models.fromName(Models.scnetVulkan.name), Models.scnetVulkan);
        expect(Models.fromName(Models.htdemucs.name), Models.htdemucs);
        expect(Models.scnetOnnx.architecture, SeparationArchitecture.scnet);
        expect(Models.scnetVulkan.stems, ['drums', 'bass', 'other', 'vocals']);
      },
    );

    test('fromName round-trips every catalog entry; unknown throws', () {
      for (final m in Models.all) {
        expect(Models.fromName(m.name).name, m.name);
      }
      expect(() => Models.fromName('nope'), throwsArgumentError);
    });

    test('GPU model resolves only on supported hosts', () {
      if (Platform.isMacOS || Platform.isIOS) {
        expect(Models.htdemucs.downloadUrl, Models.htdemucs.appleUrl);
      } else if (Platform.isAndroid) {
        expect(Models.htdemucs.downloadUrl, Models.htdemucs.androidUrl);
      } else {
        expect(Models.htdemucs.downloadUrl, isNull);
        expect(Models.recommended, Models.scnetOnnx);
      }
    });

    test('SCNet CPU is recommended on Apple while Core ML is experimental', () {
      expect(Models.scnetOnnx.isDefault, isTrue);
      expect(Models.scnetCoreMl.isDefault, isFalse);
      if (Platform.isMacOS || Platform.isIOS) {
        expect(Models.recommended, Models.scnetOnnx);
      }
    });
  });
}
