// part 'unmixed_song.g.dart';
import 'package:hive/hive.dart';

import '../constants.dart';
import 'song.dart';

part 'unmixed_song.g.dart';

@HiveType(typeId: 0)
class UnmixedSong {
  @HiveField(0)
  Song mixture;

  @HiveField(1)
  Song vocals;

  @HiveField(2)
  Song bass;

  @HiveField(3)
  Song drums;

  @HiveField(4)
  Song other;

  UnmixedSong({
    required this.mixture,
    required this.vocals,
    required this.bass,
    required this.drums,
    required this.other,
  });

  Song getStem(Stem stem) {
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
}
