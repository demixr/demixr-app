import 'package:demixr_app/models/unmixed_song.dart';
import 'package:demixr_app/repositories/library_repository.dart';
import 'package:flutter/material.dart';

class LibraryProvider extends ChangeNotifier {
  final _repository = LibraryRepository();
  List<UnmixedSong> _songs = [];

  LibraryProvider() {
    _loadSongs();
  }

  void _loadSongs() => _songs = _repository.box.values.toList();

  int get numberOfSongs => _songs.length;

  bool get isEmpty => _songs.isEmpty;

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
    _songs.removeAt(index);
    _repository.box.deleteAt(index);
    notifyListeners();
  }
}
