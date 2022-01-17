import 'dart:typed_data';

import 'package:dartz/dartz.dart';
import 'package:demixr_app/helpers/song_helper.dart';
import 'package:demixr_app/models/failure/failure.dart';
import 'package:demixr_app/models/failure/no_album_cover.dart';
import 'package:demixr_app/models/failure/no_song_selected.dart';
import 'package:demixr_app/models/song.dart';
import 'package:demixr_app/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';

class SongProvider extends ChangeNotifier {
  final _helper = SongHelper();
  final _ytHelper = SongHelper();
  final _urlFormKey = GlobalKey<FormBuilderState>();
  Either<Failure, Song> _song = Left(NoSongSelected());
  Either<Failure, Uint8List> _cover = Left(NoAlbumCover());

  Either<Failure, Song> get song => _song;

  Either<Failure, Uint8List> get cover => _cover;

  GlobalKey<FormBuilderState> get urlFormKey => _urlFormKey;

  Future<void> loadFromDevice() async {
    _song = await _helper.loadFromDevice();

    await _song.fold(
      (failure) async {
        errorSnackbar('Could not load the song', failure.message);
        _cover = Left(NoAlbumCover());
      },
      (song) async => _cover = await song.albumCover,
    );

    notifyListeners();
  }

  Future<void> downloadFromYoutube() async {
    if (_urlFormKey.currentState!.saveAndValidate()) {
      String url = _urlFormKey.currentState!.value['url'];

      _song = await _ytHelper.downloadFromYoutube(url);

      await _song.fold(
        (failure) async {
          errorSnackbar('Could not download the song', failure.message,
              seconds: 5);
          _cover = Left(NoAlbumCover());
        },
        (song) async => _cover = await song.albumCover,
      );

      notifyListeners();
    }
  }

  void removeSelectedSong() {
    _song = Left(NoSongSelected());
    _cover = Left(NoAlbumCover());
    notifyListeners();
  }
}
