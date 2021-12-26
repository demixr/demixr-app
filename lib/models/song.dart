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
}
