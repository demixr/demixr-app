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

  void update(LibraryProvider library) {
    _library = library;

    final selectedSong = library.currentSong;
    if (_song != selectedSong) {
      _song = _library.currentSong;
      bool wasPlaying = state == PlayerState.play;
      stop();
      if (wasPlaying) playpause();
    }
  }

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
        _song.fold(
          (failure) => null,
          (song) {
            _player.play(song.mixture.path);
            state = PlayerState.play;
          },
        );
        break;
    }
    notifyListeners();
  }

  void stop() {
    _player.stop();
    state = PlayerState.off;
    notifyListeners();
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
