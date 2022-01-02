import 'package:dartz/dartz.dart';
import 'package:demixr_app/models/failure/failure.dart';
import 'package:demixr_app/models/failure/no_song_selected.dart';
import 'package:demixr_app/models/unmixed_song.dart';
import 'package:demixr_app/repositories/library_repository.dart';
import 'package:flutter/material.dart';

class LibraryProvider extends ChangeNotifier {
  final _repository = LibraryRepository();
  List<UnmixedSong> _songs = [];
  Either<Failure, int> _currentSongIndex = Left(NoSongSelected());

  LibraryProvider() {
    _loadSongs();
  }

  int get numberOfSongs => _songs.length;

  bool get isEmpty => _songs.isEmpty;

  List<UnmixedSong> get songList => _songs;

  Either<Failure, UnmixedSong> get currentSong => _currentSongIndex.fold(
        (noSongSelected) => Left(noSongSelected),
        (index) => Right(getAt(index)),
      );

  bool setCurrentSongIndex(int index) {
    if (index >= numberOfSongs || index < 0) return false;

    _currentSongIndex = Right(index);
    notifyListeners();

    return true;
  }

  int getIndexByOrder(int index) => numberOfSongs - index - 1;

  UnmixedSong getAt(int index) {
    return _songs.elementAt(index);
  }

  void _loadSongs() => _songs = _repository.box.values.toList();

  Future<int> saveSong(UnmixedSong song) async {
    song.mixture = await _repository.saveFile(song.mixture);
    _repository.box.add(song);
    _songs.add(song);
    notifyListeners();
    return numberOfSongs - 1;
  }

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

  bool nextSong() {
    return _currentSongIndex.fold(
      (noSongSelected) => false,
      (index) => setCurrentSongIndex(index - 1),
    );
  }

  bool previousSong() {
    return _currentSongIndex.fold(
      (noSongSelected) => false,
      (index) => setCurrentSongIndex(index + 1),
    );
  }
}
