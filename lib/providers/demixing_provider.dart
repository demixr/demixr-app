import 'package:demixr_app/helpers/demixing_helper.dart';
import 'package:demixr_app/models/exceptions/demixing_exception.dart';
import 'package:demixr_app/models/song.dart';
import 'package:demixr_app/models/unmixed_song.dart';
import 'package:demixr_app/providers/library_provider.dart';
import 'package:demixr_app/providers/preferences_provider.dart';
import 'package:demixr_app/utils.dart';
import 'package:flutter/material.dart';
import 'package:async/async.dart';
import 'package:get/route_manager.dart';

class DemixingProvider extends ChangeNotifier {
  final _helper = DemixingHelper();
  final PreferencesProvider preferences;
  late Stream<double> _progressStream;
  CancelableOperation<UnmixedSong>? _operation;

  DemixingProvider(this.preferences);

  Stream<double> get progressStream => _progressStream;

  Future<void> unmix(Song song, LibraryProvider library) async {
    if (!(await preferences.isSelectedModelAvailable())) {
      errorSnackbar('Model unavailable',
          'The selected model is not available, download it to continue.');
      return;
    }

    _progressStream =
        _helper.progressStream.receiveBroadcastStream().cast<double>();

    separate(song)
        ?.then((unmixed) => library.saveSong(unmixed))
        .then((index) => library.setCurrentSongIndex(index))
        .then(
          (_) => Get.offAllNamed(
            '/player',
            predicate: (route) => route.settings.name == '/',
          ),
        );
  }

  CancelableOperation<UnmixedSong>? separate(Song song) {
    Get.toNamed('/demixing/processing', arguments: this);

    _operation = CancelableOperation<UnmixedSong>.fromFuture(_helper
        .separate(song, preferences.getModelPath(), preferences.modelName)
        .onError((DemixingException error, _) {
      errorSnackbar('Demixing error', error.message, seconds: 5);
      cancelDemixing();
      throw error;
    }));
    return _operation;
  }

  void cancelDemixing() {
    _operation?.cancel();
    Get.back();
  }
}
