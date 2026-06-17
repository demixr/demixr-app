import 'dart:typed_data';

import 'package:flutter_onnxruntime/flutter_onnxruntime.dart';

/// Constants and helpers for the htdemucs ONNX model.
///
/// These values are **baked into the exported ONNX graph** (input shape
/// `[1, 2, 343980]`). They must stay in lockstep with the published model: a
/// re-export with a different segment length means a new model file and a bump
/// here. The chunked overlap-add scheme mirrors the reference implementation in
/// the `demucs-onnx` Python package exactly so our output matches it.
class DemucsConfig {
  /// Sample rate the model operates at (and the rate of every stem we write).
  static const int sampleRate = 44100;

  /// Channel count of the model input/output (stereo).
  static const int channels = 2;

  /// Fixed segment length in samples (7.8 s @ 44.1 kHz) — the model's input dim.
  static const int segment = 343980;

  /// Overlap between consecutive segments (quarter of a segment).
  static const int overlap = segment ~/ 4; // 85995

  /// Hop between consecutive segment starts.
  static const int stride = segment - overlap; // 257985

  /// Model output stem order — the rows of the `[1, S, 2, N]` output tensor,
  /// in Demucs' native ordering, mapped by name to the app's stems.
  static const List<String> sources4 = ['drums', 'bass', 'other', 'vocals'];

  /// 6-stem (htdemucs_6s) output order: the 4 above plus guitar and piano.
  static const List<String> sources6 = [
    'drums',
    'bass',
    'other',
    'vocals',
    'guitar',
    'piano',
  ];

  /// The ordered model output sources for a model producing [count] stems.
  static List<String> sourcesForCount(int count) =>
      count == 6 ? sources6 : sources4;

  /// ONNX graph input/output tensor names.
  static const String inputName = 'mix';
  static const String outputName = 'stems';

  /// Builds the triangular fade-in/fade-out window used for overlap-add.
  ///
  /// Matches numpy `linspace(0, 1, transition)` on the leading edge and its
  /// reverse on the trailing edge, with ones in between.
  static Float32List buildTransitionWindow() {
    final transition = overlap; // int(segment * 0.25)
    final window = Float32List(segment);
    for (var i = 0; i < segment; i++) {
      window[i] = 1.0;
    }
    for (var i = 0; i < transition; i++) {
      final v = i / (transition - 1);
      window[i] = v; // fade in
      window[segment - 1 - i] = v; // fade out (mirror of the fade-in ramp)
    }
    return window;
  }

  /// Ordered execution-provider preference for [platform], filtered to those
  /// actually [available] on the device. CPU is always appended as a fallback.
  ///
  /// We default to **XNNPACK (a multi-threaded CPU accelerator) then CPU** on
  /// every platform. CoreML/NNAPI are deliberately *not* in the default list:
  /// htdemucs is a ~24k-node transformer graph, and on Apple the CoreML
  /// graph-compile alone costs ~16 s per session (measured: CPU 3.9 s vs
  /// CoreML 20 s for a 12 s clip on an M-series Mac) which a one-shot
  /// separation never amortizes. NNAPI is deprecated and unreliable for these
  /// graphs. CoreML/NNAPI remain reachable via `providerOverride` for
  /// benchmarking, and should only become a default if/when compiled-model
  /// caching is wired up.
  static List<OrtProvider> preferredProviders(
    String platform,
    List<OrtProvider> available,
  ) {
    final wishlist = [OrtProvider.XNNPACK, OrtProvider.CPU];
    final ordered = wishlist.where(available.contains).toList();
    if (!ordered.contains(OrtProvider.CPU)) ordered.add(OrtProvider.CPU);
    return ordered;
  }
}
