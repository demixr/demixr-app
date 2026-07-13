import 'package:flutter/material.dart';
import 'package:dartz/dartz.dart';
import 'dart:async';

import '../models/failure/failure.dart';
import '../models/failure/no_song_selected.dart';
import '../models/unmixed_song.dart';
import '../providers/library_provider.dart';
import '../services/stems_player.dart';
import '../services/system_media_handler.dart';
import '../constants.dart';

/// The sate of the music player.
enum PlayerState { play, pause, off }

/// Provider handling the music player logic.
///
/// Uses the [StemsPlayer] to play the different stems of the [_song].
class PlayerProvider extends ChangeNotifier {
  final SystemMediaHandler _mediaHandler;
  late LibraryProvider _library;
  Either<Failure, UnmixedSong> _song = Left(NoSongSelected());
  final _player = StemsPlayer();
  PlayerState state = PlayerState.off;
  Duration position = Duration.zero;
  StreamSubscription<Duration>? _positionSubscription;

  PlayerProvider(this._mediaHandler) {
    _mediaHandler.attach(
      play: () async => play(),
      pause: () async => pause(),
      seek: (position) async => seek(position),
      next: () async => next(),
      previous: () async => previous(),
    );
    _positionSubscription = positionStream.listen((position) {
      this.position = position;
      _publishMediaState();
    });
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    super.dispose();
  }

  /// The state of the player, playing or not.
  bool get isPlaying => state == PlayerState.play;

  /// The stream of the position of the player.
  Stream<Duration> get positionStream => _player.onAudioPositionChanged;

  /// The duration of the current [_song].
  Duration get songDuration =>
      _song.fold((failure) => Duration.zero, (song) => song.duration);

  /// The stems of the current song (4 or 6 depending on the model used).
  List<Stem> get stems =>
      _song.fold((failure) => const [], (song) => song.stems);

  UnmixedSong? get currentSong => _song.fold((failure) => null, (song) => song);

  Map<Stem, double> get stemVolumes => {
    for (final stem in stems) stem: _player.getStemVolume(stem),
  };

  /// Checks if a [stem] is muted or not.
  bool isStemMute(Stem stem) => _player.getStemState(stem) == StemState.mute;

  double stemVolume(Stem stem) => _player.getStemVolume(stem);

  /// Handles the updates of the [library].
  ///
  /// Start playing a new song if another song was selected from the library.
  void update(LibraryProvider library) {
    _library = library;

    final selectedSong = library.currentSong;

    // when a new song is selected
    if (_song != selectedSong) {
      // stop current song
      bool wasPlaying = isPlaying;
      stop();

      _song = _library.currentSong;

      // prepare the player
      _song.fold((failure) => null, (song) {
        _player.setUrls(song);
        _player.seek(position);
        _mediaHandler.publishSong(song);

        state = PlayerState.pause;
        _publishMediaState();

        _player.onPlayerCompletion.listen((event) {
          toStart(setPause: true);
        });
      });

      if (wasPlaying) unawaited(playpause());
    }
  }

  /// Resets the [position] of the player.
  void resetPosition() {
    position = Duration.zero;
  }

  /// Toggle the [state] of the player and plays or pauses accordingly.
  Future<void> playpause() async {
    switch (state) {
      case PlayerState.play:
        pause();
        break;
      case PlayerState.pause:
        await resume();
        break;
      case PlayerState.off:
        break;
    }
    notifyListeners();
  }

  /// Goes to the start of the song.
  void toStart({bool setPause = true}) {
    if (setPause) pause();
    resetPosition();
    seek(position);
    notifyListeners();
  }

  /// Resumes playing the current [_song].
  Future<void> resume() async {
    if (!await _player.resume()) return;
    state = PlayerState.play;
    _publishMediaState();
    notifyListeners();
  }

  /// Pauses the current [_song].
  void pause() {
    _player.pause();
    state = PlayerState.pause;
    _publishMediaState();
    notifyListeners();
  }

  /// Stops playing the current [_song], and unload it.
  void stop() {
    _player.stop();
    resetPosition();
    state = PlayerState.off;
    notifyListeners();
  }

  /// Seek the player to the given [position].
  void seek(Duration position) {
    this.position = position;
    _player.seek(position);
    _publishMediaState();
  }

  Future<void> play() async {
    if (state != PlayerState.off) await resume();
  }

  void _publishMediaState() {
    _mediaHandler.publishState(
      playing: isPlaying,
      position: position,
      bufferedPosition: songDuration,
    );
  }

  /// Play the next song in the [_library].
  void next() {
    final success = _library.nextSong();
    if (!success) toStart();
  }

  /// Play the previous song in the [_library].
  void previous() {
    if (position > const Duration(seconds: 3)) {
      toStart(setPause: false);
      return;
    }

    final success = _library.previousSong();
    if (!success) toStart(setPause: false);
  }

  /// Toggle mute / unmute on the given [stem].
  void toggleStem(Stem stem) {
    _player.toggleStem(stem);
    notifyListeners();
  }

  void setStemVolume(Stem stem, double volume) {
    _player.setStemVolume(stem, volume);
    notifyListeners();
  }
}
