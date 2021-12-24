import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:demixr_app/models/failure/failure.dart';
import 'package:demixr_app/models/failure/song_not_available.dart';
import 'package:demixr_app/models/song.dart';
import 'package:demixr_app/services/song_loader.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_media_metadata/flutter_media_metadata.dart';

class SongHelper {
  final _service = SongLoader();

  Future<Either<Failure, Song>> loadFromDevice() async {
    Either<Failure, PlatformFile> file = await _service.getFromDevice();

    return file.fold((failure) => Left(failure), (file) async {
      if (file.path == null) return Left(SongNotAvailable());

      var metadata = await MetadataRetriever.fromFile(File(file.path!));

      return Right(
        Song(
          title: metadata.trackName ?? file.name,
          artists: metadata.trackArtistNames ?? [file.name],
          cover: metadata.albumArt,
        ),
      );
    });
  }
}
