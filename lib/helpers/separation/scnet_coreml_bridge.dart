import 'dart:typed_data';

import 'package:flutter/services.dart';

class ScnetCoreMlBridge {
  static const _channel = MethodChannel('demixr/scnet_coreml');
  static String? _loadedPath;

  static Future<void> load(String modelPath) async {
    if (_loadedPath == modelPath) return;
    await _channel.invokeMethod<void>('load', {'path': modelPath});
    _loadedPath = modelPath;
  }

  static Future<Float32List> run(Float32List input) async {
    final output = await _channel.invokeMethod<Uint8List>('run', {
      'input': input,
    });
    if (output == null) throw StateError('Core ML returned no SCNet output');
    // StandardMethodCodec may place typed data at an unaligned envelope
    // offset. Copy once into an aligned buffer before exposing float32 values.
    final aligned = Uint8List.fromList(output);
    return Float32List.view(aligned.buffer);
  }
}
