import 'package:dartz/dartz.dart';
import 'package:demixr_app/helpers/song_helper.dart';
import 'package:demixr_app/models/failure/failure.dart';
import 'package:demixr_app/models/failure/no_song_selected.dart';
import 'package:demixr_app/models/song.dart';
import 'package:demixr_app/models/song_download.dart';
import 'package:demixr_app/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';

class SongProvider extends ChangeNotifier {
  final _helper = SongHelper();
  final _ytHelper = SongHelper();
  final _urlFormKey = GlobalKey<FormBuilderState>();
  Either<Failure, Song> _song = Left(NoSongSelected());
  Either<Failure, SongDownload> _songDownload = Left(NoSongSelected());

  Either<Failure, Song> get song => _song;

  Either<Failure, SongDownload> get songDownload => _songDownload;

  GlobalKey<FormBuilderState> get urlFormKey => _urlFormKey;

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

  Future<void> downloadFromYoutube() async {
    if (_urlFormKey.currentState!.saveAndValidate()) {
      String url = _urlFormKey.currentState!.value['url'];

      _song = Left(NoSongSelected());
      _songDownload = await _ytHelper.getSongInfosFromYoutube(url);

      await _songDownload.fold(
        (failure) async => errorSnackbar(
            'Could not download the song', failure.message,
            seconds: 5),
        (song) async {
          notifyListeners();
          _song = await _ytHelper.downloadFromYoutube(song);
        },
      );

      _songDownload = Left(NoSongSelected());

      _song.leftMap(
        (failure) => errorSnackbar(
            'Could not download the song', failure.message,
            seconds: 5),
      );
    }

    notifyListeners();
  }

  void removeSelectedSong() {
    _song = Left(NoSongSelected());
    notifyListeners();
  }
}
