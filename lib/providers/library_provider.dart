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

  void _loadSongs() => _songs = _repository.box.values.toList();

  int get numberOfSongs => _songs.length;

  bool get isEmpty => _songs.isEmpty;

  Either<Failure, UnmixedSong> get currentSong => _currentSongIndex.fold(
        (noSongSelected) => Left(noSongSelected),
        (index) => Right(_songs.elementAt(index)),
      );

  set currentSongIndex(int index) {
    _currentSongIndex = Right(index);
    print('Current song index was set to: $index');
    notifyListeners();
  }

  int getIndexByOrder(int index) {
    return numberOfSongs - index - 1;
  }

  UnmixedSong getAt(int index) {
    return _songs.elementAt(index);
  }

  Future<void> saveSong(UnmixedSong song) async {
    song.mixture = await _repository.saveFile(song.mixture);
    _repository.box.add(song);
    _songs.add(song);
    notifyListeners();
  }

  void removeSong(int index) {
    _repository.removeSongFiles(_songs.elementAt(index));
    _songs.removeAt(index);
    _repository.box.deleteAt(index);
    notifyListeners();
  }
}
