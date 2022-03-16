import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../models/song.dart';
import '../models/unmixed_song.dart';
import '../models/exceptions/demixing_exception.dart';
import '../utils.dart';
import '../constants.dart';

/// Helper handling the source separation.
///
/// Uses the `demixing` MethodChannel and the `demixing/progress` EventChannel
/// to communicate with the platform native code (for example Java for Android).
class DemixingHelper {
  static const _methodChannel = MethodChannel(PlatformChannels.demixing);
  static const _eventChannel = EventChannel(PlatformChannels.demixingProgress);

  /// Separates the given [song] sources in the 4 different stems.
  ///
  /// Uses the Pytorch Lite Model at the given [modelPath].
  /// Invokes the `separate` method from the native platform code.
  /// Throws a [DemixingException] if an error occures on the platform side.
  Future<UnmixedSong> separate(
      Song song, String modelPath, String modelName) async {
    Map<dynamic, dynamic> result;

    try {
      result = await _methodChannel.invokeMethod(
        'separate',
        <String, String>{
          'songPath': song.path,
          'modelPath': modelPath,
          'outputPath': await getAppTemp()
        },
      );
    } on PlatformException {
      throw DemixingException('An error occured while demixing');
    }

    final Map<String, String> separated = result.cast<String, String>();

    checkResult(separated);

    return UnmixedSong.fromSong(
      song,
      vocals: separated[Stem.vocals.value]!,
      bass: separated[Stem.bass.value]!,
      drums: separated[Stem.drums.value]!,
      other: separated[Stem.other.value]!,
      modelName: modelName,
    );
  }

  /// The demixing progress stream via the [EventChannel].
  EventChannel get progressStream => _eventChannel;

  /// Check the [separated] result to make sure all stems are present.
  void checkResult(Map<String, String> separated) {
    final stems = [
      Stem.bass.value,
      Stem.drums.value,
      Stem.other.value,
      Stem.vocals.value,
    ];

    if (!listEquals(separated.keys.toList()..sort(), stems..sort())) {
      throw DemixingException('Invalid demixing result');
    }
  }
}
