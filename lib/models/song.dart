import 'package:dartz/dartz.dart';

import 'failure/failure.dart';
import 'failure/no_album_cover.dart';

class Song {
  String title;

  List<String> artists;

  String path;

  String? coverPath;

  Song({
    required this.title,
    required this.artists,
    required this.path,
    this.coverPath,
  });

  Either<Failure, String> get albumCover =>
      coverPath == null ? Left(NoAlbumCover()) : Right(coverPath!);

  @override
  String toString() {
    return "${artists.join('_')}_$title";
  }
}
