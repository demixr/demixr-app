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
    final path = await getAppExternalStorage();
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

  Future<Song> _saveStem(Song song, String dir, String stem) async {
    String filename = "$stem.wav";
    String songPath = p.join(dir, filename);

    File songFile = File(song.path);
    final savedFile = await songFile.move(songPath);
    song.path = savedFile.path;

    return song;
  }

  Future<UnmixedSong> saveFiles(UnmixedSong song) async {
    String libraryDirectory = await _directoryPath;
    String songDirectory =
        await _createSongDirectory(libraryDirectory, song.mixture);

    song.mixture = await _saveStem(song.mixture, songDirectory, 'mixture');
    song.vocals = await _saveStem(song.vocals, songDirectory, 'vocals');
    song.bass = await _saveStem(song.bass, songDirectory, 'bass');
    song.drums = await _saveStem(song.drums, songDirectory, 'drums');
    song.other = await _saveStem(song.other, songDirectory, 'other');

    return song;
  }

  void removeSongFiles(UnmixedSong song) {
    File file = File(song.mixture.path);
    Directory directory = file.parent;
    directory.deleteSync(recursive: true);
  }
}
