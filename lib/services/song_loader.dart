import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:demixr_app/models/failure/failure.dart';
import 'package:demixr_app/models/failure/no_song_selected.dart';
import 'package:demixr_app/models/song.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_media_metadata/flutter_media_metadata.dart';

class SongLoader {
  Future<Either<Failure, Song>> getFromDevice() async {
    FilePickerResult? result =
        await FilePicker.platform.pickFiles(type: FileType.audio);

    if (result == null) return Left(NoSongSelected());

    PlatformFile file = result.files.single;
    File path = File(file.path!);
    var metadata = await MetadataRetriever.fromFile(path);

    return Right(
      Song(
        title: metadata.trackName,
        artists: metadata.trackArtistNames,
        file: path,
        cover: metadata.albumArt,
      ),
    );
  }
}
