import 'package:demixr_app/helpers/library_helper.dart';
import 'package:demixr_app/models/unmixed_song.dart';
import 'package:demixr_app/repositories/library_repository.dart';
import 'package:flutter/material.dart';

class LibraryProvider extends ChangeNotifier {
  final _repository = LibraryRepository();
  final _helper = LibraryHelper();
  List<UnmixedSong> _songs = [];

  LibraryProvider() {
    _loadSongs();
  }

  void _loadSongs() => _songs = _repository.box.values.toList();

  int get numberOfSongs => _songs.length;

  bool get isEmpty => _songs.isEmpty;

  UnmixedSong getAt(int index) {
    return _songs.elementAt(numberOfSongs - index - 1);
  }

  Future<void> saveSong(UnmixedSong song) async {
    final savedSong = await _helper.saveSong(song);
    _songs.add(savedSong);
  }
}
