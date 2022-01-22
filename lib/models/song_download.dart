import 'package:dartz/dartz.dart';

import 'failure/failure.dart';
import 'failure/no_album_cover.dart';

class SongDownload {
  String title;

  List<String> artists;

  String url;

  String? coverPath;

  Duration duration;

  SongDownload({
    required this.title,
    required this.artists,
    required this.url,
    required this.duration,
    this.coverPath,
  });

  Either<Failure, String> get albumCover =>
      coverPath == null ? Left(NoAlbumCover()) : Right(coverPath!);

  @override
  String toString() {
    return "${artists.join('_')}_$title";
  }
}
