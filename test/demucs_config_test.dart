import 'package:flutter_onnxruntime/flutter_onnxruntime.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:demixr_app/helpers/separation/demucs_config.dart';

void main() {
  group('Demucs execution providers', () {
    test('Windows prefers DirectML with CPU fallback', () {
      final providers = DemucsConfig.preferredProviders('windows', [
        OrtProvider.CPU,
        OrtProvider.DIRECT_ML,
      ]);

      expect(providers, [OrtProvider.DIRECT_ML, OrtProvider.CPU]);
    });

    test('Windows uses CPU when DirectML is unavailable', () {
      final providers = DemucsConfig.preferredProviders('windows', [
        OrtProvider.CPU,
      ]);

      expect(providers, [OrtProvider.CPU]);
    });

    test('other platforms retain XNNPACK preference', () {
      final providers = DemucsConfig.preferredProviders('linux', [
        OrtProvider.CPU,
        OrtProvider.XNNPACK,
      ]);

      expect(providers, [OrtProvider.XNNPACK, OrtProvider.CPU]);
    });
  });
}
