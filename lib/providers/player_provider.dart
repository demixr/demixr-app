import 'package:flutter/material.dart';
import 'package:dartz/dartz.dart';

import '../models/failure/failure.dart';
import '../models/failure/no_song_selected.dart';
import '../models/unmixed_song.dart';
import '../providers/library_provider.dart';
import '../services/stems_player.dart';
import '../constants.dart';

/// The sate of the music player.
enum PlayerState {
  play,
  pause,
  off,
}

/// Provider handling the music player logic.
///
/// Uses the [StemsPlayer] to play the different stems of the [_song].
class PlayerProvider extends ChangeNotifier {
  late LibraryProvider _library;
  Either<Failure, UnmixedSong> _song = Left(NoSongSelected());
  final _player = StemsPlayer();
  PlayerState state = PlayerState.off;
  Duration position = Duration.zero;

  /// The state of the player, playing or not.
  bool get isPlaying => state == PlayerState.play;

  /// The stream of the position of the player.
  Stream<Duration> get positionStream => _player.onAudioPositionChanged;

  /// The duration of the current [_song].
  Duration get songDuration =>
      _song.fold((failure) => Duration.zero, (song) => song.duration);

  /// Checks if a [stem] is muted or not.
  bool isStemMute(Stem stem) => _player.getStemState(stem) == StemState.mute;

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
      _song.fold(
        (failure) => null,
        (song) {
          _player.setUrls(song);
          _player.seek(position);

          state = PlayerState.pause;

          _player.onPlayerCompletion.listen((event) {
            toStart(setPause: true);
          });
        },
      );

      if (wasPlaying) playpause();
    }
  }

  /// Resets the [position] of the player.
  void resetPosition() {
    position = Duration.zero;
  }

  /// Toggle the [state] of the player and plays or pauses accordingly.
  void playpause() {
    switch (state) {
      case PlayerState.play:
        pause();
        break;
      case PlayerState.pause:
        resume();
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
  void resume() {
    _player.resume();
    state = PlayerState.play;
  }

  /// Pauses the current [_song].
  void pause() {
    _player.pause();
    state = PlayerState.pause;
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
  }

  /// Play the next song in the [_library].
  void next() {
    final success = _library.nextSong();
    if (!success) toStart();
  }

  /// Play the previous song in the [_library].
  void previous() {
    final success = _library.previousSong();
    if (!success) toStart(setPause: false);
  }

  /// Toggle mute / unmute on the given [stem].
  void toggleStem(Stem stem) {
    _player.toggleStem(stem);
    notifyListeners();
  }
}
