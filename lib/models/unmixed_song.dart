// part 'unmixed_song.g.dart';
import 'package:hive/hive.dart';

import 'song.dart';

part 'unmixed_song.g.dart';

@HiveType(typeId: 0)
class UnmixedSong {
  @HiveField(0)
  Song mixture;

  @HiveField(1)
  Song? vocals;

  @HiveField(2)
  Song? bass;

  @HiveField(3)
  Song? drums;

  @HiveField(4)
  Song? other;

  UnmixedSong({
    required this.mixture,
    this.vocals,
    this.bass,
    this.drums,
    this.other,
  });
}
