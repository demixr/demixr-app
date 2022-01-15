import 'package:demixr_app/helpers/demixing_helper.dart';
import 'package:demixr_app/models/exceptions/demixing_exception.dart';
import 'package:demixr_app/models/song.dart';
import 'package:demixr_app/models/unmixed_song.dart';
import 'package:demixr_app/providers/library_provider.dart';
import 'package:demixr_app/providers/preferences_provider.dart';
import 'package:demixr_app/utils.dart';
import 'package:flutter/material.dart';
import 'package:async/async.dart';

class DemixingProvider extends ChangeNotifier {
  final _helper = DemixingHelper();
  final PreferencesProvider preferences;
  bool _isDemixing = false;
  CancelableOperation<UnmixedSong>? _operation;

  DemixingProvider(this.preferences);

  bool get isDemixing => _isDemixing;

  _setStatus({required bool isDemixing}) {
    if (_isDemixing != isDemixing) {
      _isDemixing = isDemixing;
      notifyListeners();
    }
  }

  CancelableOperation<bool>? unmix(Song song, LibraryProvider library) {
    return separate(song)
        ?.then((unmixed) => library.saveSong(unmixed))
        .then((index) => library.setCurrentSongIndex(index));
  }

  CancelableOperation<UnmixedSong>? separate(Song song) {
    _setStatus(isDemixing: true);
    _operation = CancelableOperation<UnmixedSong>.fromFuture(_helper
        .separate(song, preferences.getModelPath())
        .onError((DemixingException error, _) {
      errorSnackbar('Demixing error', error.message, seconds: 5);
      cancelDemixing();
      throw error;
    }));
    return _operation;
  }

  void cancelDemixing() {
    _operation?.cancel();
    _setStatus(isDemixing: false);
  }
}
