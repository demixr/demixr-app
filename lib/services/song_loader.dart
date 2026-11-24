import 'package:dartz/dartz.dart';
import 'package:demixr_app/models/failure/failure.dart';
import 'package:demixr_app/models/failure/no_song_selected.dart';
import 'package:file_picker/file_picker.dart';

class SongLoader {
  Future<Either<Failure, PlatformFile>> getFromDevice() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['mp3', 'wav', 'flac', 'm4a', 'ogg', 'opus'],
    );

    if (result == null) return Left(NoSongSelected());

    return Right(result.files.single);
  }
}
