import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:demixr_app/models/unmixed_song.dart';
import 'package:demixr_app/services/carplay_bridge.dart';
import 'package:demixr_app/services/system_media_handler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

UnmixedSong song(String id, String title, String artist) => UnmixedSong(
  title: title,
  artists: [artist],
  duration: const Duration(minutes: 2),
  mixture: id,
  vocals: 'vocals.wav',
  bass: 'bass.wav',
  drums: 'drums.wav',
  other: 'other.wav',
  modelName: 'htdemucs',
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final newest = song('new.wav', 'Day Trip', 'The Roads');
  final oldest = song('old.wav', 'Night Drive', 'The Lights');

  test('the media browser reflects live library changes', () async {
    final handler = SystemMediaHandler();
    final changes = handler
        .subscribeToChildren(AudioService.browsableRootId)
        .take(3)
        .toList();

    expect(await handler.getChildren(AudioService.browsableRootId), isEmpty);
    handler.publishLibrary([newest, oldest]);

    final items = await handler.getChildren(AudioService.browsableRootId);
    expect(items.map((item) => item.id), [newest.mixture, oldest.mixture]);
    expect(items.every((item) => item.playable == true), isTrue);
    expect(await handler.getChildren('unknown'), isEmpty);

    handler.publishSong(oldest);
    expect(handler.mediaItem.value?.id, items.last.id);
    handler.publishLibrary([newest]);

    expect(await handler.getMediaItem(oldest.mixture), isNull);
    expect(await changes, hasLength(3));
  });

  test(
    'browse, voice and transport commands share playback callbacks',
    () async {
      final handler = SystemMediaHandler();
      final commands = <Object>[];
      handler.attach(
        play: () async => commands.add('resume'),
        pause: () async => commands.add('pause'),
        stop: () async => commands.add('stop'),
        seek: (position) async => commands.add(position),
        next: () async => commands.add('next'),
        previous: () async => commands.add('previous'),
        playSong: (id) async {
          commands.add(id);
          return true;
        },
      );
      handler.publishLibrary([newest, oldest]);

      await handler.play();
      await handler.playFromMediaId(oldest.mixture);
      await handler.playFromSearch('  LIGHTS night ');
      await handler.playFromSearch('missing song');
      handler.publishSong(oldest);
      await handler.play();
      await handler.pause();
      await handler.seek(const Duration(seconds: 15));
      await handler.skipToNext();
      await handler.skipToPrevious();
      await handler.stop();

      expect(commands, [
        newest.mixture,
        oldest.mixture,
        oldest.mixture,
        'resume',
        'pause',
        const Duration(seconds: 15),
        'next',
        'previous',
        'stop',
      ]);
    },
  );

  test('CarPlay can attach after the phone starts', () async {
    const name = 'com.demixr.demixrApp/carplay';
    const codec = StandardMethodCodec();
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

    final handler = SystemMediaHandler();
    final played = <String>[];
    handler.attach(
      play: () async {},
      pause: () async {},
      stop: () async {},
      seek: (_) async {},
      next: () async {},
      previous: () async {},
      playSong: (id) async {
        played.add(id);
        return true;
      },
    );
    CarPlayBridge(handler).start();

    // There is no native channel handler until the car scene connects.
    await Future<void>.delayed(Duration.zero);
    handler.publishLibrary([newest]);

    Future<Object?> callFromCar(MethodCall call) async {
      final reply = Completer<ByteData?>();
      await messenger.handlePlatformMessage(
        name,
        codec.encodeMethodCall(call),
        reply.complete,
      );
      return codec.decodeEnvelope((await reply.future)!);
    }

    expect(await callFromCar(const MethodCall('getLibrary')), [
      {'id': newest.mixture, 'title': newest.title, 'artist': 'The Roads'},
    ]);
    expect(await callFromCar(MethodCall('playSong', newest.mixture)), isTrue);
    expect(played, [newest.mixture]);
  });
}
