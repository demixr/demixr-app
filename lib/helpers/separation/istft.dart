import 'dart:math' as math;
import 'dart:typed_data';

import 'demucs_config.dart';

/// Inverse STFT + mask + time-branch combine, in pure Dart.
///
/// The core `.pte` stops just before the rank-6 mask/iSTFT (CoreML caps tensors
/// at rank 5), emitting the pre-mask spectral stems and the time-branch stems.
/// This reproduces htdemucs' `_mask` + `_ispec` exactly — but with an
/// O(N log N) FFT instead of the dense-DFT `ConvTranspose1d` the post `.pte`
/// used (which was the ~1.75 s/chunk bottleneck).
///
/// ### Math (matches `demucs_onnx.export.RealISTFT` + `HTDemucs._ispec`)
/// htdemucs is complex-as-channels: the spec output packs, per stem `s` and
/// audio channel `c`, the real part at spec-channel `2c` and imag at `2c+1`,
/// over `specBins` (2048) frequency bins and `specFrames` (336) time frames.
///
/// The forward STFT used `torch.stft(window=hann, n_fft=4096, hop=1024,
/// normalized=True, center=True)`, so each frame's time-domain contribution is
///
///   frame[n] = (1/√N) · w[n] · Re{ IDFT(X)[n] }       n = 0..N-1
///
/// where `X[k] = re_k + i·im_k` for `k = 0..N/2` (the dropped Nyquist bin is
/// re-added as zero, and the imag parts of DC/Nyquist are discarded — which
/// taking only the real part of the IDFT does for free). Frames are
/// overlap-added at stride `hop` with a per-sample offset of `-1536` (the
/// `_ispec`/`center` padding: `hop//2*3` minus the symmetric STFT pad), then
/// divided by the `OLA(w²)` envelope and added to the time branch.
class Istft {
  Istft()
    : _window = _hann(DemucsConfig.nFft),
      _cos = Float64List(DemucsConfig.nFft),
      _sin = Float64List(DemucsConfig.nFft),
      _rev = _bitReversal(DemucsConfig.nFft),
      _re = Float64List(DemucsConfig.nFft),
      _im = Float64List(DemucsConfig.nFft) {
    final n = DemucsConfig.nFft;
    for (var j = 0; j < n; j++) {
      final a = 2 * math.pi * j / n;
      _cos[j] = math.cos(a);
      _sin[j] = math.sin(a);
    }
    _env = _buildEnvelope();
  }

  static const int _n = DemucsConfig.nFft; // 4096
  static const int _hop = DemucsConfig.hop; // 1024
  static const int _seg = DemucsConfig.segment; // 343980
  // `_ispec` trims `hop//2*3` (1536) from the front, after the iSTFT has
  // already removed the symmetric `n_fft//2` analysis pad; the net offset of
  // STFT frame 0, sample 0 in the output is -1536.
  static const int _offset = _hop ~/ 2 * 3; // 1536
  static final double _norm = 1.0 / math.sqrt(_n);

  final Float64List _window; // hann(N), periodic
  final Float64List _cos; // cos(2πj/N)
  final Float64List _sin; // sin(2πj/N)
  final Int32List _rev; // bit-reversal permutation
  final Float64List _re; // scratch (real)
  final Float64List _im; // scratch (imag)
  late final Float64List _env; // OLA(w²) envelope, length _seg

  /// Reconstructs `[1, S, 2, segment]` time-domain stems from the core `.pte`
  /// outputs: [spec] `[1, S, 2C, specBins, specFrames]` (pre-mask, row-major)
  /// and [time] `[1, S, 2, segment]`. Returns the flattened stems, same layout
  /// as [time], ready for the overlap-add accumulator.
  Float32List run(Float32List spec, Float32List time, int sources) {
    const fr = DemucsConfig.specBins; // 2048
    const t = DemucsConfig.specFrames; // 336
    const c = DemucsConfig.channels; // 2
    final out = Float32List(sources * c * _seg);
    final ola = Float64List(_seg);

    for (var s = 0; s < sources; s++) {
      for (var ch = 0; ch < c; ch++) {
        ola.fillRange(0, _seg, 0.0);
        // Spec channels for this audio channel: real = 2*ch, imag = 2*ch+1.
        final reBase = ((s * (2 * c) + 2 * ch) * fr) * t;
        final imBase = ((s * (2 * c) + 2 * ch + 1) * fr) * t;

        for (var frame = 0; frame < t; frame++) {
          _re.fillRange(0, _n, 0.0);
          _im.fillRange(0, _n, 0.0);
          // Build the conjugate-symmetric spectrum: bins 0..fr-1 come from the
          // model, bin fr (Nyquist) stays zero, bins n-k mirror k (k=1..fr-1).
          for (var k = 0; k < fr; k++) {
            final reK = spec[reBase + k * t + frame].toDouble();
            final imK = spec[imBase + k * t + frame].toDouble();
            _re[k] = reK;
            _im[k] = imK;
            if (k >= 1) {
              _re[_n - k] = reK;
              _im[_n - k] = -imK;
            }
          }
          _ifft(_re, _im);

          final base = frame * _hop - _offset;
          var lo = base < 0 ? -base : 0;
          var hi = _n;
          if (base + hi > _seg) hi = _seg - base;
          for (var j = lo; j < hi; j++) {
            ola[base + j] += _norm * _window[j] * _re[j];
          }
        }

        final outBase = (s * c + ch) * _seg;
        for (var i = 0; i < _seg; i++) {
          out[outBase + i] = time[outBase + i] + ola[i] / _env[i];
        }
      }
    }
    return out;
  }

  /// In-place inverse FFT (unnormalised, `+i` sign). Real part of the result is
  /// `N · irfft`; the `1/N` is folded into [_norm] at the call site.
  void _ifft(Float64List re, Float64List im) {
    final n = _n;
    for (var i = 0; i < n; i++) {
      final j = _rev[i];
      if (j > i) {
        var tmp = re[i];
        re[i] = re[j];
        re[j] = tmp;
        tmp = im[i];
        im[i] = im[j];
        im[j] = tmp;
      }
    }
    for (var len = 2; len <= n; len <<= 1) {
      final half = len >> 1;
      final step = n ~/ len;
      for (var i = 0; i < n; i += len) {
        var idx = 0;
        for (var j = i; j < i + half; j++) {
          final wr = _cos[idx];
          final wi = _sin[idx]; // +sin => inverse transform
          final vr = re[j + half];
          final vi = im[j + half];
          final tr = vr * wr - vi * wi;
          final ti = vr * wi + vi * wr;
          re[j + half] = re[j] - tr;
          im[j + half] = im[j] - ti;
          re[j] += tr;
          im[j] += ti;
          idx += step;
        }
      }
    }
  }

  /// `OLA(w²)` over the padded frame range `fv ∈ [-2, specFrames+1]` — the two
  /// extra frames at each edge are the zero-padded frames `_ispec` adds on the
  /// time axis, which contribute to the envelope though not to the signal.
  Float64List _buildEnvelope() {
    final env = Float64List(_seg);
    const t = DemucsConfig.specFrames;
    for (var fv = -2; fv <= t + 1; fv++) {
      final base = fv * _hop - _offset;
      var lo = base < 0 ? -base : 0;
      var hi = _n;
      if (base + hi > _seg) hi = _seg - base;
      for (var j = lo; j < hi; j++) {
        env[base + j] += _window[j] * _window[j];
      }
    }
    for (var i = 0; i < _seg; i++) {
      if (env[i] < 1e-11) env[i] = 1e-11;
    }
    return env;
  }

  static Float64List _hann(int n) {
    final w = Float64List(n);
    for (var i = 0; i < n; i++) {
      w[i] = 0.5 - 0.5 * math.cos(2 * math.pi * i / n); // periodic
    }
    return w;
  }

  static Int32List _bitReversal(int n) {
    final rev = Int32List(n);
    var bits = 0;
    while ((1 << bits) < n) {
      bits++;
    }
    for (var i = 0; i < n; i++) {
      var x = i, r = 0;
      for (var b = 0; b < bits; b++) {
        r = (r << 1) | (x & 1);
        x >>= 1;
      }
      rev[i] = r;
    }
    return rev;
  }
}
