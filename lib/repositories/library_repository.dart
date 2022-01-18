import 'dart:io';
import 'package:demixr_app/models/unmixed_song.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path/path.dart' as p;

import '../constants.dart';
import '../utils.dart';

class LibraryRepository {
  final _box = Hive.box<UnmixedSong>(BoxesNames.library);
  final _directoryName = 'library';

  Box<UnmixedSong> get box => _box;

  Future<String> get _directoryPath async {
    final path = await getAppExternalStorage();
    var directory = Directory(p.join(path, _directoryName));
    directory = await directory.createIfNotPresent();
    return directory.path;
  }

  Future<String> _createSongDirectory(
      String libraryDirectory, UnmixedSong song) async {
    var directory = Directory(p.join(libraryDirectory, song.toString()));
    directory = await directory.createUnique();
    return directory.path;
  }

  Future<String> _saveStem(String path, String name, String dir) async {
    String filename = "$name.wav";
    String newPath = p.join(dir, filename);

    File stemFile = File(path);
    final savedFile = await stemFile.move(newPath);

    return savedFile.path;
  }

  Future<UnmixedSong> saveFiles(UnmixedSong song) async {
    String libraryDirectory = await _directoryPath;
    String songDirectory = await _createSongDirectory(libraryDirectory, song);

    song.mixture =
        await _saveStem(song.mixture, Stem.mixture.name, songDirectory);
    song.vocals = await _saveStem(song.vocals, Stem.vocals.name, songDirectory);
    song.bass = await _saveStem(song.bass, Stem.bass.name, songDirectory);
    song.drums = await _saveStem(song.drums, Stem.drums.name, songDirectory);
    song.other = await _saveStem(song.other, Stem.other.name, songDirectory);

    if (song.coverPath != null) {
      String newPath = p.join(songDirectory, p.basename(song.coverPath!));
      song.coverPath = (await File(song.coverPath!).move(newPath)).path;
    }

    return song;
  }

  void removeSongFiles(UnmixedSong song) {
    File file = File(song.mixture);
    Directory directory = file.parent;
    directory.deleteSync(recursive: true);
  }
}
