import 'dart:io';

import 'package:audio_service/audio_service.dart';

import '../models/unmixed_song.dart';

class SystemMediaHandler extends BaseAudioHandler {
  Future<void> Function()? onPlay;
  Future<void> Function()? onPause;
  Future<void> Function(Duration position)? onSeek;
  Future<void> Function()? onNext;
  Future<void> Function()? onPrevious;

  void attach({
    required Future<void> Function() play,
    required Future<void> Function() pause,
    required Future<void> Function(Duration position) seek,
    required Future<void> Function() next,
    required Future<void> Function() previous,
  }) {
    onPlay = play;
    onPause = pause;
    onSeek = seek;
    onNext = next;
    onPrevious = previous;
  }

  void publishSong(UnmixedSong song) {
    final coverPath = song.coverPath;
    mediaItem.add(
      MediaItem(
        id: song.mixture,
        title: song.title,
        artist: song.artists.join(', '),
        album: 'Demixr · ${song.modelName}',
        duration: song.duration,
        artUri: coverPath != null && File(coverPath).existsSync()
            ? Uri.file(coverPath)
            : null,
      ),
    );
  }

  void publishState({
    required bool playing,
    required Duration position,
    required Duration bufferedPosition,
  }) {
    playbackState.add(
      playbackState.value.copyWith(
        controls: [
          MediaControl.skipToPrevious,
          playing ? MediaControl.pause : MediaControl.play,
          MediaControl.skipToNext,
        ],
        systemActions: const {MediaAction.seek},
        androidCompactActionIndices: const [0, 1, 2],
        processingState: AudioProcessingState.ready,
        playing: playing,
        updatePosition: position,
        bufferedPosition: bufferedPosition,
        speed: 1,
      ),
    );
  }

  @override
  Future<void> play() async => onPlay?.call();

  @override
  Future<void> pause() async => onPause?.call();

  @override
  Future<void> seek(Duration position) async => onSeek?.call(position);

  @override
  Future<void> skipToNext() async => onNext?.call();

  @override
  Future<void> skipToPrevious() async => onPrevious?.call();
}
