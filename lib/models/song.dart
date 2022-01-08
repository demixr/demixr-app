import 'package:hive/hive.dart';

part 'song.g.dart';

@HiveType(typeId: 1)
class Song {
  @HiveField(0)
  String title;

  @HiveField(1)
  List<String> artists;

  @HiveField(2)
  String path;

  Song({required this.title, required this.artists, required this.path});

  @override
  String toString() {
    return "${artists.join('_')}_$title";
  }

  Song.stem(Song song, String? path)
      : this(title: song.title, artists: song.artists, path: path ?? song.path);
}
