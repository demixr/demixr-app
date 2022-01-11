import 'package:demixr_app/models/song.dart';
import 'package:demixr_app/models/unmixed_song.dart';
import 'package:demixr_app/utils.dart';
import 'package:flutter/services.dart';

class DemixingHelper {
  static const platform = MethodChannel('demixing');

  Future<UnmixedSong> separate(Song song, String modelPath) async {
    // TODO: Run the platform channel code in a background task

    final Map<dynamic, dynamic> result = await platform.invokeMethod(
      'separate',
      <String, String>{
        'songPath': song.path,
        'modelPath': modelPath,
        'outputPath': await getAppTemp()
      },
    );

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
