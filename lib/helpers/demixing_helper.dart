import 'package:demixr_app/constants.dart';
import 'package:demixr_app/models/song.dart';
import 'package:demixr_app/models/unmixed_song.dart';
import 'package:demixr_app/utils.dart';
import 'package:flutter/services.dart';

class DemixingHelper {
  static const platform = MethodChannel('demixing');

  Future<UnmixedSong> separate(Song song) async {
    final int result = await platform.invokeMethod(
      'separate',
      <String, dynamic>{
        'songPath': song.path,
        'modelPath': Models.umxl,
        'outputPath': await getAppTemp()
      },
    );

    // TODO: Real source separation implementation

    await Future.delayed(const Duration(seconds: 5));

    return UnmixedSong(
      mixture: song,
    );
  }
}
