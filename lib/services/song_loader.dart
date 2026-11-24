import 'package:dartz/dartz.dart';
import 'package:demixr_app/models/failure/failure.dart';
import 'package:demixr_app/models/failure/no_song_selected.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

class SongLoader {
  static const _supportedExtensions = [
    'mp3',
    'wav',
    'flac',
    'm4a',
    'ogg',
    'opus',
  ];

  Future<Either<Failure, PlatformFile>> getFromDevice() async {
    // Android providers can report M4A as audio/mp4 or audio/x-m4a.
    final useAudioPicker = defaultTargetPlatform == TargetPlatform.android;
    final result = await FilePicker.pickFiles(
      type: useAudioPicker ? FileType.audio : FileType.custom,
      allowedExtensions: useAudioPicker ? null : _supportedExtensions,
    );

    if (result == null) return Left(NoSongSelected());

    final file = result.files.single;
    final extension = p
        .extension(file.name)
        .toLowerCase()
        .replaceFirst('.', '');
    if (!_supportedExtensions.contains(extension)) {
      return Left(
        Failure(
          message:
              'Unsupported audio format. Choose one of: ${_supportedExtensions.join(', ')}.',
        ),
      );
    }

    return Right(file);
  }
}
