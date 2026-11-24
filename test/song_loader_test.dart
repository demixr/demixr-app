import 'package:demixr_app/models/failure/no_song_selected.dart';
import 'package:demixr_app/services/song_loader.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('miguelruivo.flutter.plugins.filepicker');
  final messenger = binding.defaultBinaryMessenger;

  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  for (final extension in ['flac', 'mp3', 'wav']) {
    test('allows selecting a $extension file from the device', () async {
      final name = 'song.$extension';
      final path = '/cache/$name';
      messenger.setMockMethodCallHandler(channel, (call) async {
        expect(call.method, 'custom');
        expect(call.arguments['allowedExtensions'], contains(extension));
        expect(call.arguments['allowMultipleSelection'], isFalse);
        return [
          {'name': name, 'path': path, 'size': 100},
        ];
      });

      final result = await SongLoader().getFromDevice();

      result.fold(
        (failure) => fail('Expected a picked file, got $failure'),
        (file) => expect(file.path, path),
      );
    });
  }

  test('returns NoSongSelected when the picker is cancelled', () async {
    messenger.setMockMethodCallHandler(channel, (_) async => null);

    final result = await SongLoader().getFromDevice();

    result.fold(
      (failure) => expect(failure, isA<NoSongSelected>()),
      (_) => fail('Expected the picker to be cancelled'),
    );
  });
}
