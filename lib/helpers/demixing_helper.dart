import 'package:demixr_app/models/exceptions/demixing_exception.dart';
import 'package:demixr_app/models/song.dart';
import 'package:demixr_app/models/unmixed_song.dart';
import 'package:demixr_app/utils.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../constants.dart';

class DemixingHelper {
  static const platform = MethodChannel('demixing');

  Future<UnmixedSong> separate(Song song, String modelPath) async {
    Map<dynamic, dynamic> result;

    try {
      result = await platform.invokeMethod(
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
      vocals: separated['vocals']!,
      drums: separated['drums']!,
      bass: separated['bass']!,
      other: separated['other']!,
    );
  }

  void checkResult(Map<String, String> separated) {
    final stems = [
      Stem.vocals.name,
      Stem.bass.name,
      Stem.drums.name,
      Stem.other.name,
    ];

    if (listEquals(separated.keys.toList(), stems)) {
      throw DemixingException('Invalid demixing result');
    }
  }
}
