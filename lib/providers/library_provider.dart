import 'package:flutter/material.dart';
import 'package:dartz/dartz.dart';

import '../models/unmixed_song.dart';
import '../models/failure/failure.dart';
import '../models/failure/no_song_selected.dart';
import '../repositories/library_repository.dart';

/// Provider for the unmixed songs library.
///
/// Uses the [LibraryRepository] to store and get the songs.
class LibraryProvider extends ChangeNotifier {
  final _repository = LibraryRepository();
  List<UnmixedSong> _songs = [];
  Either<Failure, int> _currentSongIndex = Left(NoSongSelected());

  LibraryProvider() {
    _loadSongs();
  }

  /// The number of songs in the library.
  int get numberOfSongs => _songs.length;

  /// The state of the library, empty or not.
  bool get isEmpty => _songs.isEmpty;

  /// List of the songs in the library.
  List<UnmixedSong> get songList => _songs;

  /// The current selected song, from it's index.
  Either<Failure, UnmixedSong> get currentSong => _currentSongIndex.fold(
        (noSongSelected) => Left(noSongSelected),
        (index) => Right(getAt(index)),
      );

  /// Sets the current song [index].
  bool setCurrentSongIndex(int index) {
    if (index >= numberOfSongs || index < 0) return false;

    _currentSongIndex = Right(index);
    notifyListeners();

    return true;
  }

  /// Returns an index based on the chosen display order, here reverse.
  int getIndexByOrder(int index) => numberOfSongs - index - 1;

  /// Returns true if the given [index] matches the currently selected song.
  bool matchSelectedSong(int index) => _currentSongIndex.fold(
      (noSongSelected) => false, (songIndex) => index == songIndex);

  /// Returns the [UnmixedSong] at the given [index].
  UnmixedSong getAt(int index) {
    return _songs.elementAt(index);
  }

  /// Loads the songs stored in the [_repository] in [_songs].
  void _loadSongs() => _songs = _repository.box.values.toList();

  /// Saves the given [song] in the [_repository].
  ///
  /// Returns the index of the saved song.
  Future<int> saveSong(UnmixedSong song) async {
    song = await _repository.saveFiles(song);
    _repository.box.add(song);
    _songs.add(song);
    notifyListeners();
    return numberOfSongs - 1;
  }

  /// Removes the song at the given [index] from the library.
  void removeSong(int index) {
    // if the song to remove is the selected song, unselect it
    _currentSongIndex.fold(
      (noSongSelected) => null,
      (currIndex) {
        if (index == currIndex) _currentSongIndex = Left(NoSongSelected());
      },
    );

    _repository.removeSongFiles(getAt(index));

    _songs.removeAt(index);
    _repository.box.deleteAt(index);

    notifyListeners();
  }

  /// Selects the next song in the library.
  bool nextSong() {
    return _currentSongIndex.fold(
      (noSongSelected) => false,
      (index) => setCurrentSongIndex(index - 1),
    );
  }

  /// Selects the previous in the library.
  bool previousSong() {
    return _currentSongIndex.fold(
      (noSongSelected) => false,
      (index) => setCurrentSongIndex(index + 1),
    );
  }
}
