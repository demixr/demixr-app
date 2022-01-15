import 'package:demixr_app/models/exceptions/demixing_exception.dart';
import 'package:demixr_app/models/song.dart';
import 'package:demixr_app/models/unmixed_song.dart';
import 'package:demixr_app/utils.dart';
import 'package:flutter/services.dart';

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

    return UnmixedSong(
      mixture: song,
      vocals: Song.stem(song, separated['vocals']),
      drums: Song.stem(song, separated['drums']),
      bass: Song.stem(song, separated['bass']),
      other: Song.stem(song, separated['other']),
    );
  }
}
