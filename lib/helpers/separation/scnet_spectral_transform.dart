import 'dart:math' as math;
import 'dart:typed_data';

import 'scnet_config.dart';

class ScnetSpectrum {
  final Float32List values;
  final double mean;
  final double std;
  const ScnetSpectrum(this.values, this.mean, this.std);
}

/// Exact Dart counterpart of SCNet's rectangular-window, normalized
/// torch.stft/istft wrapper. Keeping this outside either runtime guarantees
/// ONNX and ExecuTorch receive identical tensors.
class ScnetSpectralTransform {
  static const _n = ScnetConfig.nFft;
  static const _hop = ScnetConfig.hop;
  static const _bins = ScnetConfig.bins;
  static const _frames = ScnetConfig.frames;
  static final double _sqrtN = math.sqrt(_n);

  final _cos = Float64List(_n);
  final _sin = Float64List(_n);
  final _rev = _bitReversal(_n);
  final _re = Float64List(_n);
  final _im = Float64List(_n);

  ScnetSpectralTransform() {
    for (var i = 0; i < _n; i++) {
      final angle = 2 * math.pi * i / _n;
      _cos[i] = math.cos(angle);
      _sin[i] = math.sin(angle);
    }
  }

  ScnetSpectrum forward(Float32List channelMajorWaveform) {
    final out = Float32List(ScnetConfig.channels * 2 * _bins * _frames);
    var sum = 0.0;
    var sumSquares = 0.0;
    for (var channel = 0; channel < ScnetConfig.channels; channel++) {
      final waveBase = channel * ScnetConfig.segment;
      for (var frame = 0; frame < _frames; frame++) {
        final start = frame * _hop - _n ~/ 2;
        for (var j = 0; j < _n; j++) {
          final index = _reflect(start + j, ScnetConfig.padded);
          _re[j] = index < ScnetConfig.segment
              ? channelMajorWaveform[waveBase + index]
              : 0.0;
          _im[j] = 0.0;
        }
        _fft(inverse: false);
        for (var bin = 0; bin < _bins; bin++) {
          final real = _re[bin] / _sqrtN;
          final imag = _im[bin] / _sqrtN;
          final realIndex = ((channel * 2) * _bins + bin) * _frames + frame;
          final imagIndex = ((channel * 2 + 1) * _bins + bin) * _frames + frame;
          out[realIndex] = real;
          out[imagIndex] = imag;
          sum += real + imag;
          sumSquares += real * real + imag * imag;
        }
      }
    }
    final count = out.length;
    final mean = sum / count;
    final variance = (sumSquares - count * mean * mean) / (count - 1);
    final std = math.sqrt(math.max(variance, 0));
    final scale = 1e-5 + std;
    for (var i = 0; i < out.length; i++) {
      out[i] = (out[i] - mean) / scale;
    }
    return ScnetSpectrum(out, mean, std);
  }

  Float32List inverse(Float32List normalizedStems, double mean, double std) {
    final out = Float32List(
      ScnetConfig.sources * ScnetConfig.channels * ScnetConfig.segment,
    );
    final reconstructedLength = (_frames - 1) * _hop;
    final ola = Float64List(reconstructedLength + _n);
    final weight = Float64List(reconstructedLength + _n);
    for (var source = 0; source < ScnetConfig.sources; source++) {
      for (var channel = 0; channel < ScnetConfig.channels; channel++) {
        ola.fillRange(0, ola.length, 0);
        weight.fillRange(0, weight.length, 0);
        for (var frame = 0; frame < _frames; frame++) {
          _re.fillRange(0, _n, 0);
          _im.fillRange(0, _n, 0);
          for (var bin = 0; bin < _bins; bin++) {
            final realIndex =
                (((source * 4 + channel * 2) * _bins + bin) * _frames) + frame;
            final imagIndex =
                (((source * 4 + channel * 2 + 1) * _bins + bin) * _frames) +
                frame;
            final real = normalizedStems[realIndex] * std + mean;
            final imag = normalizedStems[imagIndex] * std + mean;
            _re[bin] = real;
            _im[bin] = imag;
            if (bin > 0 && bin < _n ~/ 2) {
              _re[_n - bin] = real;
              _im[_n - bin] = -imag;
            }
          }
          _fft(inverse: true);
          final base = frame * _hop;
          for (var j = 0; j < _n; j++) {
            ola[base + j] += _re[j] / _sqrtN;
            weight[base + j] += 1.0;
          }
        }
        final outBase =
            (source * ScnetConfig.channels + channel) * ScnetConfig.segment;
        const trim = _n ~/ 2;
        for (var i = 0; i < ScnetConfig.segment; i++) {
          final index = i + trim;
          out[outBase + i] = ola[index] / math.max(weight[index], 1e-11);
        }
      }
    }
    return out;
  }

  void _fft({required bool inverse}) {
    for (var i = 0; i < _n; i++) {
      final j = _rev[i];
      if (j > i) {
        var value = _re[i];
        _re[i] = _re[j];
        _re[j] = value;
        value = _im[i];
        _im[i] = _im[j];
        _im[j] = value;
      }
    }
    for (var length = 2; length <= _n; length <<= 1) {
      final half = length >> 1;
      final step = _n ~/ length;
      for (var offset = 0; offset < _n; offset += length) {
        var angleIndex = 0;
        for (var j = offset; j < offset + half; j++) {
          final wr = _cos[angleIndex];
          final wi = inverse ? _sin[angleIndex] : -_sin[angleIndex];
          final tr = _re[j + half] * wr - _im[j + half] * wi;
          final ti = _re[j + half] * wi + _im[j + half] * wr;
          _re[j + half] = _re[j] - tr;
          _im[j + half] = _im[j] - ti;
          _re[j] += tr;
          _im[j] += ti;
          angleIndex += step;
        }
      }
    }
  }

  static int _reflect(int index, int length) {
    while (index < 0 || index >= length) {
      if (index < 0) index = -index;
      if (index >= length) index = 2 * length - 2 - index;
    }
    return index;
  }

  static Int32List _bitReversal(int n) {
    final result = Int32List(n);
    var bits = 0;
    while ((1 << bits) < n) {
      bits++;
    }
    for (var i = 0; i < n; i++) {
      var value = i;
      var reversed = 0;
      for (var bit = 0; bit < bits; bit++) {
        reversed = (reversed << 1) | (value & 1);
        value >>= 1;
      }
      result[i] = reversed;
    }
    return result;
  }
}
