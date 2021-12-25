import 'package:demixr_app/models/song.dart';
import 'package:flutter/material.dart';

class DemixingProvider extends ChangeNotifier {
  bool _isDemixing = false;

  bool get isDemixing => _isDemixing;

  void unmixSong(Song song) {
    _isDemixing = true;

    // TODO: service call for the demixing implementation

    notifyListeners();
  }

  void cancelDemixing() {
    if (isDemixing) {
      _isDemixing = false;
      notifyListeners();
    }
  }
}
