import 'dart:typed_data';

import 'package:dartz/dartz.dart';
import 'package:demixr_app/helpers/song_helper.dart';
import 'package:demixr_app/models/failure/failure.dart';
import 'package:demixr_app/models/failure/no_album_cover.dart';
import 'package:demixr_app/models/failure/no_song_selected.dart';
import 'package:demixr_app/models/song.dart';
import 'package:flutter/material.dart';

class SongProvider extends ChangeNotifier {
  final _helper = SongHelper();
  Either<Failure, Song> _song = Left(NoSongSelected());
  Either<Failure, Uint8List> _cover = Left(NoAlbumCover());

  Either<Failure, Song> get song => _song;

  Either<Failure, Uint8List> get cover => _cover;

  Future<void> loadFromDevice() async {
    _song = await _helper.loadFromDevice();

    _song.fold(
      (failure) => _cover = Left(NoAlbumCover()),
      (song) async => _cover = await song.albumCover,
    );

    notifyListeners();
  }
}
