import 'package:demixr_app/models/song.dart';
import 'package:demixr_app/models/unmixed_song.dart';

class DemixingHelper {
  Future<UnmixedSong> separate(Song song) async {
    // Fake implementation for now
    // TODO: Real source separation implementation
    await Future.delayed(const Duration(seconds: 5));

    return UnmixedSong(
      mixture: song,
    );
  }
}
