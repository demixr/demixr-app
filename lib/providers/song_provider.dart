import 'package:flutter/material.dart';
import 'package:dartz/dartz.dart';

import '../helpers/song_helper.dart';
import '../models/song.dart';
import '../models/song_download.dart';
import '../models/failure/failure.dart';
import '../models/failure/no_song_selected.dart';
import '../utils.dart';

/// Provider handling the song selection before the demixing.
///
/// Uses the [SongHelper] to load from the device or youtube.
class SongProvider extends ChangeNotifier {
  final _helper = SongHelper();
  Either<Failure, Song> _song = Left(NoSongSelected());
  Either<Failure, SongDownload> _songDownload = Left(NoSongSelected());

  /// The selected song.
  Either<Failure, Song> get song => _song;

  /// The song currently being downloaded.
  Either<Failure, SongDownload> get songDownload => _songDownload;

  /// Loads a song from the device, using the [SongHelper].
  Future<void> loadFromDevice() async {
    _song = await _helper.loadFromDevice();

    await _song.fold(
      (failure) async {
        if (failure != NoSongSelected()) {
          errorSnackbar('Could not load the song', failure.message);
        }
      },
      (song) => null,
    );

    notifyListeners();
  }

  /// Downloads a song from youtube with the given [url] using the [SongHelper].
  Future<void> downloadFromYoutube(String url) async {
    _song = Left(NoSongSelected());
    _songDownload = await _helper.getSongInfosFromYoutube(url);

    await _songDownload.fold(
      (failure) async => errorSnackbar(
          'Could not download the song', failure.message,
          seconds: 5),
      (song) async {
        notifyListeners();
        _song = await _helper.downloadFromYoutube(song);
      },
    );

    _songDownload = Left(NoSongSelected());

    _song.leftMap(
      (failure) => errorSnackbar('Could not download the song', failure.message,
          seconds: 5),
    );

    notifyListeners();
  }

  /// Removes the currently selected song.
  void removeSelectedSong() {
    _song = Left(NoSongSelected());
    notifyListeners();
  }
}
