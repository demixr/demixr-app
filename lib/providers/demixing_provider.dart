import 'package:demixr_app/helpers/demixing_helper.dart';
import 'package:demixr_app/helpers/library_helper.dart';
import 'package:demixr_app/models/song.dart';
import 'package:demixr_app/models/unmixed_song.dart';
import 'package:flutter/material.dart';

class DemixingProvider extends ChangeNotifier {
  final _helper = DemixingHelper();
  final _library = LibraryHelper();
  bool _isDemixing = false;

  bool get isDemixing => _isDemixing;

  _setStatus({required bool isDemixing}) {
    if (_isDemixing != isDemixing) {
      _isDemixing = isDemixing;
      notifyListeners();
    }
  }

  void unmix(Song song) {
    _setStatus(isDemixing: true);

    _helper.separate(song).then((UnmixedSong song) {
      _library.saveSong(song);
      _setStatus(isDemixing: false);
    });
  }

  void cancelDemixing() {
    _setStatus(isDemixing: false);
  }
}
