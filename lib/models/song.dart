import 'package:dartz/dartz.dart';
import 'package:demixr_app/models/song_download.dart';

import 'failure/failure.dart';
import 'failure/no_album_cover.dart';

class Song {
  String title;

  List<String> artists;

  String path;

  String? coverPath;

  Duration duration;

  Song({
    required this.title,
    required this.artists,
    required this.path,
    required this.duration,
    this.coverPath,
  });

  Song.fromDownload(SongDownload song, String path)
      : this(
          title: song.title,
          artists: song.artists,
          coverPath: song.coverPath,
          path: path,
          duration: song.duration,
        );

  Either<Failure, String> get albumCover =>
      coverPath == null ? Left(NoAlbumCover()) : Right(coverPath!);

  @override
  String toString() {
    return "${artists.join('_')}_$title";
  }
}
