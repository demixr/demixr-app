import 'dart:io';

import 'package:demixr_app/utils.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('plugins.flutter.io/path_provider');

  test('creates the app cache directory when it is missing', () async {
    final parent = await Directory.systemTemp.createTemp();
    addTearDown(() => parent.delete(recursive: true));
    final cache = Directory(p.join(parent.path, 'Caches', 'demixr'));

    final messenger = binding.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(channel, (call) async {
      expect(call.method, 'getTemporaryDirectory');
      return cache.path;
    });
    addTearDown(() => messenger.setMockMethodCallHandler(channel, null));

    expect(await getAppTemp(), cache.path);
    expect(await cache.exists(), isTrue);
  });
}
