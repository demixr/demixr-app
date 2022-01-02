import 'package:audioplayers/audioplayers.dart';
import 'package:dartz/dartz.dart';
import 'package:demixr_app/models/failure/failure.dart';
import 'package:demixr_app/models/failure/no_song_selected.dart';
import 'package:demixr_app/models/unmixed_song.dart';
import 'package:demixr_app/providers/library_provider.dart';
import 'package:flutter/material.dart';

enum PlayerState {
  play,
  pause,
  off,
}

class PlayerProvider extends ChangeNotifier {
  late LibraryProvider _library;
  Either<Failure, UnmixedSong> _song = Left(NoSongSelected());
  final AudioPlayer _player = AudioPlayer();
  PlayerState state = PlayerState.off;
  Duration position = Duration.zero;

  bool get isPlaying => state == PlayerState.play;

  Stream<Duration> get positionStream => _player.onAudioPositionChanged;

  Future<int> get songDuration async => _player.getDuration();

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
          _player.setUrl(song.mixture.path, isLocal: true);
          state = PlayerState.pause;
        },
      );

      if (wasPlaying) playpause();
    }
  }

  void resetPosition() => position = Duration.zero;

  void playpause() {
    switch (state) {
      case PlayerState.play:
        _player.pause();
        state = PlayerState.pause;
        break;
      case PlayerState.pause:
        _player.resume();
        state = PlayerState.play;
        break;
      case PlayerState.off:
        break;
    }
    notifyListeners();
  }

  void stop() {
    _player.stop();
    resetPosition();
    state = PlayerState.off;
    notifyListeners();
  }

  void seek(Duration position) {
    this.position = position;
    _player.seek(position);
  }

  void next() {
    final success = _library.nextSong();
    if (!success) stop();
  }

  void previous() {
    final success = _library.previousSong();
    if (!success) stop();
  }
}
