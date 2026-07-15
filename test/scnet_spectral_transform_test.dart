import 'dart:math' as math;
import 'dart:typed_data';

import 'package:demixr_app/helpers/separation/scnet_config.dart';
import 'package:demixr_app/helpers/separation/scnet_spectral_transform.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'SCNet spectral conversion round-trips a stereo signal',
    () {
      final waveform = Float32List(ScnetConfig.channels * ScnetConfig.segment);
      for (var channel = 0; channel < ScnetConfig.channels; channel++) {
        for (var i = 0; i < ScnetConfig.segment; i++) {
          waveform[channel * ScnetConfig.segment + i] =
              0.2 * math.sin(2 * math.pi * (220 + channel * 110) * i / 44100);
        }
      }
      final transform = ScnetSpectralTransform();
      final spectrum = transform.forward(waveform);
      final duplicated = Float32List(
        spectrum.values.length * ScnetConfig.sources,
      );
      for (var source = 0; source < ScnetConfig.sources; source++) {
        duplicated.setRange(
          source * spectrum.values.length,
          (source + 1) * spectrum.values.length,
          spectrum.values,
        );
      }
      final reconstructed = transform.inverse(
        duplicated,
        spectrum.mean,
        spectrum.std,
      );
      var maximumError = 0.0;
      for (var i = 0; i < waveform.length; i++) {
        maximumError = math.max(
          maximumError,
          (waveform[i] - reconstructed[i]).abs(),
        );
      }
      expect(maximumError, lessThan(1e-4));
    },
    timeout: const Timeout(Duration(minutes: 2)),
  );
}
