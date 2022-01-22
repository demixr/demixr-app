import 'package:demixr_app/models/exceptions/demixing_exception.dart';
import 'package:demixr_app/models/song.dart';
import 'package:demixr_app/models/unmixed_song.dart';
import 'package:demixr_app/utils.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../constants.dart';

class DemixingHelper {
  static const _methodChannel = MethodChannel(PlatformChannels.demixing);
  static const _eventChannel = EventChannel(PlatformChannels.demixingProgress);

  Future<UnmixedSong> separate(Song song, String modelPath) async {
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
    );
  }

  EventChannel get progressStream => _eventChannel;

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
