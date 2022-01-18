// part 'unmixed_song.g.dart';
import 'package:dartz/dartz.dart';
import 'package:demixr_app/models/failure/no_album_cover.dart';
import 'package:hive/hive.dart';

import '../constants.dart';
import 'failure/failure.dart';
import 'song.dart';

part 'unmixed_song.g.dart';

@HiveType(typeId: 0)
class UnmixedSong {
  @HiveField(0)
  String title;

  @HiveField(1)
  List<String> artists;

  @HiveField(2)
  String? coverPath;

  @HiveField(3)
  String mixture;

  @HiveField(4)
  String vocals;

  @HiveField(5)
  String bass;

  @HiveField(6)
  String drums;

  @HiveField(7)
  String other;

  UnmixedSong({
    required this.title,
    required this.artists,
    required this.mixture,
    required this.vocals,
    required this.bass,
    required this.drums,
    required this.other,
    this.coverPath,
  });

  UnmixedSong.fromSong(
    Song song, {
    required String vocals,
    required String bass,
    required String drums,
    required String other,
  }) : this(
          title: song.title,
          artists: song.artists,
          coverPath: song.coverPath,
          mixture: song.path,
          vocals: vocals,
          bass: bass,
          drums: drums,
          other: other,
        );

  String getStem(Stem stem) {
    switch (stem) {
      case Stem.mixture:
        return mixture;
      case Stem.vocals:
        return vocals;
      case Stem.drums:
        return drums;
      case Stem.bass:
        return bass;
      case Stem.other:
        return other;
    }
  }

  Either<Failure, String> get albumCover =>
      coverPath == null ? Left(NoAlbumCover()) : Right(coverPath!);

  @override
  String toString() {
    return "${artists.join('_')}_$title";
  }
}
