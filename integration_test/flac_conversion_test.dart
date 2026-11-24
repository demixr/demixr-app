import 'dart:convert';
import 'dart:io';

import 'package:demixr_app/helpers/song_helper.dart';
import 'package:demixr_app/utils.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path/path.dart' as p;

// A 20 ms, 440 Hz tone encoded as FLAC.
const _flacTone =
    'ZkxhQwAAACICQAJAAAB6AAB6AfQA8AAAAKBwC8cRJ/DJQ389m2vWzZEGhAAALg0AAABM'
    'YXZmNjIuMTIuMTAxAQAAABUAAABlbmNvZGVyPUxhdmY2Mi4xMi4xMDH/+GQIAJ83TgAA'
    'BWsKMg3FD7YPzQ4FCpTlmWC9KmZDfRisjx0hH78oAEpe/kIgTBEMpC9XfuymIwgiGmr8'
    'qqsyMIwjG2688Hy7GQQxDUz1XL3sxGIIQmI8V373cRCCMZtlosFrkURiGMxuR15S19EM'
    'whCE0vLy95ASqg==';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  test('converts FLAC without overwriting a same-named WAV', () async {
    final inputDir = await Directory(await getAppTemp()).createTemp();
    addTearDown(() => inputDir.delete(recursive: true));

    final source = File(p.join(inputDir.path, 'test tone.flac'));
    await source.writeAsBytes(base64Decode(_flacTone));
    final existing = File(p.setExtension(source.path, '.wav'));
    await existing.writeAsString('existing file');

    final output = File(await convertToWav(source.path));
    expect(output.path, isNot(existing.path));
    addTearDown(() => output.parent.delete(recursive: true));

    final bytes = await output.readAsBytes();
    expect(bytes.length, greaterThan(44));
    expect(ascii.decode(bytes.sublist(0, 4)), 'RIFF');
    expect(ascii.decode(bytes.sublist(8, 12)), 'WAVE');
    expect(await existing.readAsString(), 'existing file');
  });
}
