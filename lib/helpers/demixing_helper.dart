import 'package:demixr_app/constants.dart';
import 'package:demixr_app/models/song.dart';
import 'package:demixr_app/models/unmixed_song.dart';
import 'package:demixr_app/utils.dart';
import 'package:flutter/services.dart';

class DemixingHelper {
  static const platform = MethodChannel('demixing');

  Future<UnmixedSong> separate(Song song) async {
    final Map<String, String> result = await platform.invokeMethod(
      'separate',
      <String, String>{
        'songPath': song.path,
        'modelAssetName': Models.umxl,
        'outputPath': await getAppTemp()
      },
    );

    return UnmixedSong(
      mixture: song,
      vocals: Song.stem(song, result['vocals']),
      drums: Song.stem(song, result['drums']),
      bass: Song.stem(song, result['bass']),
      other: Song.stem(song, result['other']),
    );
  }
}
