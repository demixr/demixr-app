import 'dart:typed_data';

class ScnetConfig {
  static const sampleRate = 44100;
  static const channels = 2;
  static const sources = 4;
  static const segment = 343980;
  static const stride = segment * 3 ~/ 4;
  static const nFft = 4096;
  static const hop = 1024;
  static const padded = 345088;
  static const bins = 2049;
  static const frames = 338;
  static const inputName = 'mix_spec';
  static const outputName = 'stems_spec';
  static const sourceNames = ['drums', 'bass', 'other', 'vocals'];

  static Float32List buildTransitionWindow() {
    final window = Float32List(segment);
    final half = segment / 2;
    for (var i = 0; i < segment; i++) {
      window[i] = (1.0 - ((i - half).abs() / half)).clamp(1e-3, 1.0);
    }
    return window;
  }
}
