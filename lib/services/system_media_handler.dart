import 'dart:io';

import 'package:audio_service/audio_service.dart';
import 'package:rxdart/rxdart.dart';

import '../models/unmixed_song.dart';

class SystemMediaHandler extends BaseAudioHandler {
  final _libraryChanged = BehaviorSubject<Map<String, dynamic>>.seeded(
    const {},
  );
  List<MediaItem> _library = const [];

  late final Future<void> Function() _play;
  late final Future<void> Function() _pause;
  late final Future<void> Function() _stop;
  late final Future<void> Function(Duration position) _seek;
  late final Future<void> Function() _next;
  late final Future<void> Function() _previous;
  late final Future<bool> Function(String id) _playSong;

  void attach({
    required Future<void> Function() play,
    required Future<void> Function() pause,
    required Future<void> Function() stop,
    required Future<void> Function(Duration position) seek,
    required Future<void> Function() next,
    required Future<void> Function() previous,
    required Future<bool> Function(String id) playSong,
  }) {
    _play = play;
    _pause = pause;
    _stop = stop;
    _seek = seek;
    _next = next;
    _previous = previous;
    _playSong = playSong;
  }

  MediaItem _mediaItemFor(UnmixedSong song) {
    final coverPath = song.coverPath;
    return MediaItem(
      id: song.mixture,
      title: song.title,
      artist: song.artists.join(', '),
      album: 'Demixr · ${song.modelName}',
      duration: song.duration,
      artUri: coverPath != null && File(coverPath).existsSync()
          ? Uri.file(coverPath)
          : null,
    );
  }

  void publishLibrary(Iterable<UnmixedSong> songs) {
    _library = List.unmodifiable(songs.map(_mediaItemFor));
    _libraryChanged.add(const {});
  }

  void publishSong(UnmixedSong? song) {
    mediaItem.add(song == null ? null : _mediaItemFor(song));
  }

  Future<void> prepareToPlay({
    required Duration position,
    required Duration bufferedPosition,
  }) async {
    if (!Platform.isAndroid || playbackState.value.playing) return;

    // audio_service promotes the media service when it receives playing=true.
    // Android 15+ needs that before a headless player can obtain audio focus.
    publishState(
      ready: true,
      playing: true,
      position: position,
      bufferedPosition: bufferedPosition,
      buffering: true,
    );
    await Future<void>.delayed(Duration.zero);
  }

  void publishState({
    required bool ready,
    required bool playing,
    required Duration position,
    required Duration bufferedPosition,
    bool buffering = false,
  }) {
    playbackState.add(
      playbackState.value.copyWith(
        controls: ready
            ? [
                MediaControl.skipToPrevious,
                playing ? MediaControl.pause : MediaControl.play,
                MediaControl.skipToNext,
              ]
            : const [],
        systemActions: {
          MediaAction.playFromMediaId,
          MediaAction.playFromSearch,
          if (ready) MediaAction.seek,
        },
        androidCompactActionIndices: ready ? const [0, 1, 2] : const [],
        processingState: buffering
            ? AudioProcessingState.buffering
            : ready
            ? AudioProcessingState.ready
            : AudioProcessingState.idle,
        playing: playing,
        updatePosition: position,
        bufferedPosition: bufferedPosition,
        speed: 1,
      ),
    );
  }

  @override
  Future<List<MediaItem>> getChildren(
    String parentMediaId, [
    Map<String, dynamic>? options,
  ]) async =>
      parentMediaId == AudioService.browsableRootId ? _library : const [];

  @override
  ValueStream<Map<String, dynamic>> subscribeToChildren(String parentMediaId) =>
      parentMediaId == AudioService.browsableRootId
      ? _libraryChanged
      : super.subscribeToChildren(parentMediaId);

  @override
  Future<MediaItem?> getMediaItem(String mediaId) async =>
      _library.where((item) => item.id == mediaId).firstOrNull;

  @override
  Future<List<MediaItem>> search(
    String query, [
    Map<String, dynamic>? extras,
  ]) async {
    final terms = query.trim().toLowerCase().split(RegExp(r'\s+'));
    return _library.where((item) {
      final text = '${item.title} ${item.artist ?? ''}'.toLowerCase();
      return terms.every(text.contains);
    }).toList();
  }

  @override
  Future<void> playFromSearch(
    String query, [
    Map<String, dynamic>? extras,
  ]) async {
    if (query.trim().isEmpty) {
      await play();
      return;
    }
    final match = (await search(query, extras)).firstOrNull;
    if (match != null) await playFromMediaId(match.id);
  }

  @override
  Future<void> playFromMediaId(
    String mediaId, [
    Map<String, dynamic>? extras,
  ]) async {
    await playSong(mediaId);
  }

  Future<bool> playSong(String mediaId) => _playSong(mediaId);

  @override
  Future<void> play() async {
    if (mediaItem.value == null) {
      final first = _library.firstOrNull;
      if (first != null) await playSong(first.id);
    } else {
      await _play();
    }
  }

  @override
  Future<void> pause() => _pause();

  @override
  Future<void> stop() => _stop();

  @override
  Future<void> seek(Duration position) => _seek(position);

  @override
  Future<void> skipToNext() => _next();

  @override
  Future<void> skipToPrevious() => _previous();
}
