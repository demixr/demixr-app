import 'package:demixr_app/helpers/demixing_helper.dart';
import 'package:demixr_app/models/song.dart';
import 'package:demixr_app/models/unmixed_song.dart';
import 'package:flutter/material.dart';

class DemixingProvider extends ChangeNotifier {
  final _helper = DemixingHelper();
  bool _isDemixing = false;

  bool get isDemixing => _isDemixing;

  _setStatus({required bool isDemixing}) {
    if (_isDemixing != isDemixing) {
      _isDemixing = isDemixing;
      notifyListeners();
    }
  }

  Future<UnmixedSong> unmix(Song song) async {
    _setStatus(isDemixing: true);
    return await _helper.separate(song);
  }

  void cancelDemixing() {
    _setStatus(isDemixing: false);
  }
}
