import 'package:demixr_app/models/failure/no_song_selected.dart';
import 'package:demixr_app/services/song_loader.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('miguelruivo.flutter.plugins.filepicker');
  final messenger = binding.defaultBinaryMessenger;
  const extensions = ['mp3', 'wav', 'flac', 'm4a', 'ogg', 'opus'];

  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
    messenger.setMockMethodCallHandler(channel, null);
  });

  void pick(String name, {void Function(MethodCall)? verify}) {
    messenger.setMockMethodCallHandler(channel, (call) async {
      verify?.call(call);
      return [
        {'name': name, 'path': '/cache/$name', 'size': 100},
      ];
    });
  }

  test('filters by extension on iOS', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    pick(
      'song.m4a',
      verify: (call) {
        expect(call.method, 'custom');
        expect(call.arguments['allowedExtensions'], extensions);
        expect(call.arguments['allowMultipleSelection'], isFalse);
      },
    );

    expect((await SongLoader().getFromDevice()).isRight(), isTrue);
  });

  for (final extension in extensions) {
    test('accepts .$extension from the Android file picker', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      final name = 'song.${extension.toUpperCase()}';
      pick(
        name,
        verify: (call) {
          expect(call.method, 'any');
          expect(call.arguments['allowedExtensions'], isNull);
          expect(call.arguments['allowMultipleSelection'], isFalse);
        },
      );

      final result = await SongLoader().getFromDevice();

      result.fold(
        (failure) => fail('Expected a picked file, got $failure'),
        (file) => expect(file.path, '/cache/$name'),
      );
    });
  }

  test('rejects unsupported files from the Android file picker', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    pick('song.mid');

    final result = await SongLoader().getFromDevice();

    result.fold(
      (failure) =>
          expect(failure.message, contains('Unsupported audio format')),
      (_) => fail('Expected an unsupported format error'),
    );
  });

  test('returns NoSongSelected when the picker is cancelled', () async {
    messenger.setMockMethodCallHandler(channel, (_) async => null);

    final result = await SongLoader().getFromDevice();

    result.fold(
      (failure) => expect(failure, isA<NoSongSelected>()),
      (_) => fail('Expected the picker to be cancelled'),
    );
  });
}
