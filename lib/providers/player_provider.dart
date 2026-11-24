import 'dart:async';

import 'package:flutter/foundation.dart';

import '../constants.dart';
import '../models/unmixed_song.dart';
import '../services/stems_player.dart';
import '../services/system_media_handler.dart';
import 'library_provider.dart';

enum PlayerState { play, pause, off }

/// Controls the same stem player for Flutter and the system media session.
class PlayerProvider extends ChangeNotifier {
  final LibraryProvider _library;
  final SystemMediaHandler _mediaHandler;
  final _player = StemsPlayer();
  List<UnmixedSong> _catalog = const [];
  UnmixedSong? _selectedSong;
  UnmixedSong? _song;
  Future<void> _pending = Future.value();
  PlayerState state = PlayerState.off;
  Duration position = Duration.zero;
  late final StreamSubscription<Duration> _positionSubscription;
  late final StreamSubscription<void> _completionSubscription;

  PlayerProvider(this._library, this._mediaHandler) {
    _mediaHandler.attach(
      play: play,
      pause: pause,
      stop: stop,
      seek: seek,
      next: next,
      previous: previous,
      playSong: _playSong,
    );
    _positionSubscription = positionStream.listen((position) {
      if (!isPlaying) return;
      this.position = position;
      _publishMediaState();
    });
    _completionSubscription = _player.onPlayerCompletion.listen((_) {
      final completedSong = _song;
      unawaited(
        _enqueue(() async {
          if (_song == completedSong && isPlaying) {
            await _toStart(setPause: true);
          }
        }),
      );
    });
    _library.addListener(_updateLibrary);
    _updateLibrary();
  }

  @override
  void dispose() {
    _library.removeListener(_updateLibrary);
    _positionSubscription.cancel();
    _completionSubscription.cancel();
    super.dispose();
  }

  bool get isPlaying => state == PlayerState.play;
  Stream<Duration> get positionStream => _player.onAudioPositionChanged;
  Duration get songDuration => _song?.duration ?? Duration.zero;
  List<Stem> get stems => _song?.stems ?? const [];
  UnmixedSong? get currentSong => _song;

  Map<Stem, double> get stemVolumes => {
    for (final stem in stems) stem: _player.getStemVolume(stem),
  };

  bool isStemMute(Stem stem) => _player.getStemState(stem) == StemState.mute;

  double stemVolume(Stem stem) => _player.getStemVolume(stem);

  void _updateLibrary() {
    final songs = _library.newestFirst.toList();
    if (!listEquals(_catalog, songs)) {
      _catalog = songs;
      _mediaHandler.publishLibrary(songs);
    }

    final selected = _library.currentSong.fold((_) => null, (song) => song);
    if (_selectedSong == selected) return;
    _selectedSong = selected;
    unawaited(_enqueue(() => _loadSong(selected)));
  }

  // Source changes and transport commands must reach all stems in order,
  // including a dashboard Play command while a song is still loading.
  Future<void> _enqueue(Future<void> Function() operation) {
    final result = _pending.then((_) => operation());
    _pending = result.catchError((Object error, StackTrace stack) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stack,
          library: 'Demixr playback',
        ),
      );
    });
    return result;
  }

  Future<void> _loadSong(UnmixedSong? song) async {
    final wasPlaying = isPlaying;
    // Ignore position events from the previous song during the switch.
    state = PlayerState.off;
    _song = null;
    position = Duration.zero;
    try {
      await _player.unload();
      if (song != null) {
        await _player.setUrls(song);
        _song = song;
        state = PlayerState.pause;
      }
    } finally {
      _mediaHandler.publishSong(_song);
      if (!wasPlaying || _song == null) {
        _publishMediaState();
        notifyListeners();
      }
    }
    if (wasPlaying && _song != null) await _resume();
  }

  Future<bool> _playSong(String id) async {
    final index = _library.songList.indexWhere((song) => song.mixture == id);
    if (!_library.setCurrentSongIndex(index)) return false;
    final requestedSong = _selectedSong;
    await _enqueue(() async {
      if (_song != null && _song == requestedSong) await _resume();
    });
    return _song == requestedSong && isPlaying;
  }

  Future<void> playpause() => _enqueue(() async {
    if (isPlaying) {
      await _pause();
    } else {
      await _resume();
    }
  });

  Future<void> _resume() async {
    if (_song == null || isPlaying) return;
    try {
      await _mediaHandler.prepareToPlay(
        position: position,
        bufferedPosition: songDuration,
      );
      if (await _player.resume()) state = PlayerState.play;
    } finally {
      _publishMediaState();
      notifyListeners();
    }
  }

  Future<void> _pause() async {
    if (!isPlaying) return;
    await _player.pause();
    state = PlayerState.pause;
    _publishMediaState();
    notifyListeners();
  }

  Future<void> play() => _enqueue(_resume);
  Future<void> pause() => _enqueue(_pause);

  Future<void> stop() => _enqueue(() async {
    if (_song == null) return;
    await _player.pause();
    await _player.seek(Duration.zero);
    state = PlayerState.off;
    position = Duration.zero;
    _publishMediaState();
    notifyListeners();
  });

  Future<void> seek(Duration position) => _enqueue(() => _seek(position));

  Future<void> _seek(Duration position) async {
    if (_song == null) return;
    final target = position < Duration.zero
        ? Duration.zero
        : position > songDuration
        ? songDuration
        : position;
    await _player.seek(target);
    this.position = target;
    _publishMediaState();
  }

  void _publishMediaState() {
    _mediaHandler.publishState(
      ready: state != PlayerState.off,
      playing: isPlaying,
      position: position,
      bufferedPosition: songDuration,
    );
  }

  Future<void> _toStart({required bool setPause}) async {
    if (setPause) await _pause();
    await _seek(Duration.zero);
    notifyListeners();
  }

  Future<void> next() async {
    if (_library.nextSong()) {
      await _pending;
    } else {
      await _enqueue(() => _toStart(setPause: true));
    }
  }

  Future<void> previous() async {
    if (position <= const Duration(seconds: 3) && _library.previousSong()) {
      await _pending;
    } else {
      await _enqueue(() => _toStart(setPause: false));
    }
  }

  void toggleStem(Stem stem) {
    _player.toggleStem(stem);
    notifyListeners();
  }

  void setStemVolume(Stem stem, double volume) {
    _player.setStemVolume(stem, volume);
    notifyListeners();
  }
}
