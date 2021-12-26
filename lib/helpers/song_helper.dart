import 'dart:io';
import 'dart:typed_data';

import 'package:dartz/dartz.dart';
import 'package:demixr_app/constants.dart';
import 'package:demixr_app/models/failure/failure.dart';
import 'package:demixr_app/models/failure/song_load_failure.dart';
import 'package:demixr_app/models/song.dart';
import 'package:demixr_app/services/song_loader.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_media_metadata/flutter_media_metadata.dart';
import 'package:path/path.dart';

class SongHelper {
  final _service = SongLoader();

  Future<Either<Failure, Song>> loadFromDevice() async {
    Either<Failure, PlatformFile> file = await _service.getFromDevice();

    return file.fold((failure) => Left(failure), (file) async {
      if (file.path == null) return Left(SongLoadFailure());

      File path = File(file.path!);
      var metadata = await MetadataRetriever.fromFile(path);

      Tuple2<String, List<String>> songInfos = _getSongInfos(
        metadata.trackName,
        metadata.trackArtistNames,
        basenameWithoutExtension(path.path),
      );

      return Right(
        Song(
          title: songInfos.value1,
          artists: songInfos.value2,
          path: file.path!,
        ),
      );
    });
  }

  Future<Uint8List?> getSongCover(Song song) async {
    var metadata = await MetadataRetriever.fromFile(File(song.path));
    return metadata.albumArt;
  }

  Tuple2<String, List<String>> _getSongInfos(
    String? title,
    List<String>? artists,
    String filename,
  ) {
    const separator = songArtistTitleSeparator;
    var splitedFilename = filename.split(separator);
    var titleFromFilename = splitedFilename.length == 1
        ? splitedFilename[0].trim()
        : splitedFilename.sublist(1).join(separator).trim();

    title ??= titleFromFilename;
    artists ??= [splitedFilename[0].trim()];

    return Tuple2(title, artists);
  }
}
