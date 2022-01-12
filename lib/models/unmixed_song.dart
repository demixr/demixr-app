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

  Song getStem(Stems stem) {
    switch (stem) {
      case Stems.mixture:
        return mixture;
      case Stems.vocals:
        return vocals;
      case Stems.drums:
        return drums;
      case Stems.bass:
        return bass;
      case Stems.other:
        return other;
    }
  }
}
