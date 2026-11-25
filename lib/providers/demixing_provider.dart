import 'package:flutter/material.dart';
import 'package:async/async.dart';
import 'package:get/route_manager.dart';

import '../helpers/demixing_helper.dart';
import '../models/exceptions/demixing_exception.dart';
import '../models/song.dart';
import '../models/unmixed_song.dart';
import '../providers/library_provider.dart';
import '../providers/preferences_provider.dart';
import '../utils.dart';

/// Provider handling the demixing logic.
///
/// Uses the [DemixingHelper] to start the separation with the right model
/// based on the [preferences].
class DemixingProvider extends ChangeNotifier {
  final _helper = DemixingHelper();
  final PreferencesProvider preferences;
  late Stream<double> _progressStream;
  CancelableOperation<UnmixedSong>? _operation;

  DemixingProvider(this.preferences);

  /// The stream of the demixing progress
  Stream<double> get progressStream => _progressStream;

  /// Starts the demixing for the provided [song] if a model is available.
  ///
  /// Runs the separation and save the unmixed song in the [library] on success.
  Future<void> unmix(Song song, LibraryProvider library) async {
    if (!(await preferences.isSelectedModelAvailable())) {
      errorSnackbar(
        'Model unavailable',
        'The selected model is not available, download it to continue.',
      );
      return;
    }

    _progressStream = _helper.progressStream;

    final operation = separate(song);
    if (operation == null) return;
    try {
      final unmixed = await operation.valueOrCancellation();
      if (unmixed == null) return;
      final index = await library.saveSong(unmixed);
      library.setCurrentSongIndex(index);
      Get.offAllNamed(
        '/player',
        predicate: (route) => route.settings.name == '/',
      );
    } on DemixingException catch (error) {
      errorSnackbar('Demixing error', error.message, seconds: 5);
      if (Get.currentRoute == '/demixing/processing') Get.back();
    } finally {
      _operation = null;
    }
  }

  /// Creates a cancelable async operation for the separation of the [song].
  ///
  /// Calls the [DemixingHelper] to separate and throws a [DemixingException]
  /// on error.
  CancelableOperation<UnmixedSong>? separate(Song song) {
    Get.toNamed('/demixing/processing', arguments: this);

    _operation = CancelableOperation<UnmixedSong>.fromFuture(
      _helper.separate(song, preferences.getModelPath(), preferences.modelName),
    );
    return _operation;
  }

  /// Cancel the current demixing [_operation].
  void cancelDemixing() {
    _operation?.cancel();
    Get.back();
  }
}
