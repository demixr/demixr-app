// Standalone on-device validation entrypoint (not part of the shipping app).
//
// Run with:
//   flutter run -d <device> -t tool/device_check.dart
//
// It downloads the shipping htdemucs model to a file (exactly like the real
// app), synthesizes a short tone, runs the ONNX engine, and prints clearly
// marked results to stdout so we can confirm ONNX Runtime executes htdemucs on
// the device. Watch the run output for lines beginning "DEVICE_CHECK".
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'package:demixr_app/constants.dart';
import 'package:demixr_app/helpers/onnx/audio_io.dart';
import 'package:demixr_app/helpers/onnx/demucs_config.dart';
import 'package:demixr_app/helpers/onnx/onnx_demixing_engine.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const _CheckApp());
}

class _CheckApp extends StatefulWidget {
  const _CheckApp();
  @override
  State<_CheckApp> createState() => _CheckAppState();
}

class _CheckAppState extends State<_CheckApp> {
  String _status = 'starting...';

  void _log(String m) {
    // ignore: avoid_print
    print('DEVICE_CHECK $m');
    if (mounted) setState(() => _status = m);
  }

  @override
  void initState() {
    super.initState();
    _run();
  }

  Future<void> _run() async {
    try {
      _log('platform=${Platform.operatingSystem}');
      final dir = (await getApplicationDocumentsDirectory()).path;
      final modelPath = p.join(dir, 'htdemucs_fp16weights.onnx');

      if (!File(modelPath).existsSync() ||
          File(modelPath).lengthSync() < 1000000) {
        _log('downloading model...');
        await Dio().download(Models.htdemucs.url, modelPath,
            options: Options(receiveTimeout: const Duration(minutes: 10)));
      }
      _log('model ready: ${File(modelPath).lengthSync()} bytes');

      final inputPath = p.join(dir, 'tone.wav');
      await _writeTone(inputPath, seconds: 6);

      final outDir = p.join(dir, 'out');
      await Directory(outDir).create(recursive: true);

      _log('running engine...');
      final sw = Stopwatch()..start();
      final stems = await OnnxDemixingEngine().separate(
        modelPath: modelPath,
        inputPath: inputPath,
        outputDir: outDir,
        sources: DemucsConfig.sources4,
        onProgress: (pr) => _log('progress ${(pr * 100).toStringAsFixed(0)}%'),
      );
      sw.stop();

      final ok = {'vocals', 'drums', 'bass', 'other'}
          .every((s) => stems.containsKey(s) &&
              File(stems[s]!).existsSync() &&
              File(stems[s]!).lengthSync() > 44);
      _log('RESULT stems=${stems.keys.toList()} ok=$ok '
          'took=${sw.elapsedMilliseconds}ms');
      _log(ok ? 'PASS' : 'FAIL');
    } catch (e, st) {
      _log('ERROR $e');
      // ignore: avoid_print
      print(st);
    }
  }

  Future<void> _writeTone(String path, {required int seconds}) async {
    const sr = DemucsConfig.sampleRate;
    final n = seconds * sr;
    final left = Float32List(n), right = Float32List(n);
    for (var i = 0; i < n; i++) {
      final t = i / sr;
      left[i] = 0.2 * sin(2 * pi * 220 * t);
      right[i] = 0.2 * sin(2 * pi * 330 * t);
    }
    final w = await WavWriter.create(path,
        sampleRate: sr, channels: 2, totalFrames: n);
    w.addFrames([left, right], 0, n);
    await w.close();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(_status, textAlign: TextAlign.center),
        )),
      ),
    );
  }
}
