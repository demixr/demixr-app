// part 'unmixed_song.g.dart';
import 'package:dartz/dartz.dart';
import 'package:demixr_app/models/failure/no_album_cover.dart';
import 'package:hive_ce/hive.dart';

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
  Duration duration;

  @HiveField(4)
  String mixture;

  @HiveField(5)
  String vocals;

  @HiveField(6)
  String bass;

  @HiveField(7)
  String drums;

  @HiveField(8)
  String other;

  @HiveField(9)
  String modelName;

  /// Extra stems produced by 6-stem models (htdemucs_6s). Null for 4-stem
  /// songs — kept nullable so existing Hive records remain valid.
  @HiveField(10)
  String? guitar;

  @HiveField(11)
  String? piano;

  UnmixedSong({
    required this.title,
    required this.artists,
    required this.duration,
    required this.mixture,
    required this.vocals,
    required this.bass,
    required this.drums,
    required this.other,
    required this.modelName,
    this.guitar,
    this.piano,
    this.coverPath,
  });

  /// Builds an [UnmixedSong] from a stem-name -> file-path map (the demixing
  /// result), supporting both 4-stem and 6-stem models.
  UnmixedSong.fromSeparation(
    Song song,
    Map<String, String> stems, {
    required String modelName,
  }) : this(
         title: song.title,
         artists: song.artists,
         duration: song.duration,
         coverPath: song.coverPath,
         mixture: song.path,
         vocals: stems[Stem.vocals.value]!,
         bass: stems[Stem.bass.value]!,
         drums: stems[Stem.drums.value]!,
         other: stems[Stem.other.value]!,
         guitar: stems[Stem.guitar.value],
         piano: stems[Stem.piano.value],
         modelName: modelName,
       );

  /// The stems this song actually contains, in display order (excludes the
  /// mixture, which is handled separately by the player).
  List<Stem> get stems => [
    Stem.vocals,
    Stem.drums,
    Stem.bass,
    Stem.other,
    if (guitar != null) Stem.guitar,
    if (piano != null) Stem.piano,
  ];

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
      case Stem.guitar:
        return guitar!;
      case Stem.piano:
        return piano!;
    }
  }

  Either<Failure, String> get albumCover =>
      coverPath == null ? Left(NoAlbumCover()) : Right(coverPath!);

  @override
  String toString() {
    return "${artists.join('_')}_$title";
  }
}
