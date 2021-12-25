import 'package:dartz/dartz.dart';
import 'package:demixr_app/helpers/song_helper.dart';
import 'package:demixr_app/models/failure/failure.dart';
import 'package:demixr_app/models/failure/no_song_selected.dart';
import 'package:demixr_app/models/song.dart';
import 'package:flutter/material.dart';

class SongProvider extends ChangeNotifier {
  final _helper = SongHelper();
  Either<Failure, Song> _song = Left(NoSongSelected());

  Either<Failure, Song> get song => _song;

  Future<void> loadFromDevice() async {
    _song = await _helper.loadFromDevice();
    notifyListeners();
  }

  void unmixSong() {}
}
