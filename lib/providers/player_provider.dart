import 'package:dartz/dartz.dart';
import 'package:demixr_app/models/failure/failure.dart';
import 'package:demixr_app/models/failure/no_song_selected.dart';
import 'package:demixr_app/models/unmixed_song.dart';
import 'package:demixr_app/providers/library_provider.dart';
import 'package:demixr_app/services/stems_player.dart';
import 'package:flutter/material.dart';

import '../constants.dart';

enum PlayerState {
  play,
  pause,
  off,
}

class PlayerProvider extends ChangeNotifier {
  late LibraryProvider _library;
  Either<Failure, UnmixedSong> _song = Left(NoSongSelected());
  final _player = StemsPlayer();
  PlayerState state = PlayerState.off;
  Duration position = Duration.zero;

  bool get isPlaying => state == PlayerState.play;

  Stream<Duration> get positionStream => _player.onAudioPositionChanged;

  Future<int> get songDuration async => await _player.getDuration();

  bool isStemMute(Stem stem) => _player.getStemState(stem) == StemState.mute;

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
            toStart();
          });
        },
      );

      if (wasPlaying) playpause();
    }
  }

  void resetPosition() {
    position = Duration.zero;
  }

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

  void toStart({bool setPause = true}) {
    if (setPause) pause();
    resetPosition();
    seek(position);
    notifyListeners();
  }

  void resume() {
    _player.resume();
    state = PlayerState.play;
  }

  void pause() {
    _player.pause();
    state = PlayerState.pause;
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
    if (!success) toStart();
  }

  void previous() {
    final success = _library.previousSong();
    if (!success) toStart(setPause: false);
  }

  void toggleStem(Stem stem) {
    _player.toggleStem(stem);
    notifyListeners();
  }
}
