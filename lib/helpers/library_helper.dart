import 'package:demixr_app/models/unmixed_song.dart';
import 'package:demixr_app/repositories/library_repository.dart';

class LibraryHelper {
  final _repository = LibraryRepository();

  Future<void> saveSong(UnmixedSong song) async {
    song.mixture = await _repository.saveFile(song.mixture);
    _repository.add(song);
  }
}
