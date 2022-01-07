import 'dart:io';
import 'package:demixr_app/models/song.dart';
import 'package:demixr_app/models/unmixed_song.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path/path.dart' as p;

import '../utils.dart';
import '../constants.dart' show BoxesNames;

class LibraryRepository {
  final _box = Hive.box<UnmixedSong>(BoxesNames.library);
  final _directoryName = 'library';

  Box<UnmixedSong> get box => _box;

  Future<String> get _directoryPath async {
    final path = await getAppStorage();
    var directory = Directory(p.join(path, _directoryName));
    directory = await directory.createIfNotPresent();
    return directory.path;
  }

  Future<String> _createSongDirectory(
      String libraryDirectory, Song song) async {
    var directory = Directory(p.join(libraryDirectory, song.toString()));
    directory = await directory.createUnique();
    return directory.path;
  }

  Future<Song> saveFile(Song song) async {
    String libraryDirectory = await _directoryPath;
    String songDirectory = await _createSongDirectory(libraryDirectory, song);
    String filename = "mixture${p.extension(song.path)}";
    String songPath = p.join(songDirectory, filename);

    final savedFile = await moveFile(File(song.path), songPath);
    song.path = savedFile.path;

    return song;
  }

  void removeSongFiles(UnmixedSong song) {
    File file = File(song.mixture.path);
    Directory directory = file.parent;
    directory.deleteSync(recursive: true);
  }
}
