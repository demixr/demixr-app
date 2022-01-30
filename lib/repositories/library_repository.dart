import 'dart:io';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:path/path.dart' as p;

import '../models/unmixed_song.dart';
import '../constants.dart';
import '../utils.dart';

/// Repository for the library local persistence.
///
/// Uses Hive to store the songs, and saves the files in the app
/// external storage.
class LibraryRepository {
  final _box = Hive.box<UnmixedSong>(BoxesNames.library);
  final _directoryName = 'library';

  /// The Hive box.
  Box<UnmixedSong> get box => _box;

  /// The library directory path on the file system.
  Future<String> get _directoryPath async {
    final path = await getAppExternalStorage();
    var directory = Directory(p.join(path, _directoryName));
    directory = await directory.createIfNotPresent();
    return directory.path;
  }

  /// Creates the directory for the given [song] in the library.
  Future<String> _createSongDirectory(
      String libraryDirectory, UnmixedSong song) async {
    var directory = Directory(p.join(libraryDirectory, song.toString()));
    directory = await directory.createUnique();
    return directory.path;
  }

  /// Saves the the stem file at the [path] to the specified [dir].
  Future<String> _saveStem(String path, String name, String dir) async {
    String filename = "$name.wav";
    String newPath = p.join(dir, filename);

    File stemFile = File(path);
    final savedFile = await stemFile.move(newPath);

    return savedFile.path;
  }

  /// Saves the files of the unmixed [song] to the library directory.
  ///
  /// Saves the different stems as well as the cover if there is one.
  Future<UnmixedSong> saveFiles(UnmixedSong song) async {
    String libraryDirectory = await _directoryPath;
    String songDirectory = await _createSongDirectory(libraryDirectory, song);

    song.mixture =
        await _saveStem(song.mixture, Stem.mixture.value, songDirectory);
    song.vocals =
        await _saveStem(song.vocals, Stem.vocals.value, songDirectory);
    song.bass = await _saveStem(song.bass, Stem.bass.value, songDirectory);
    song.drums = await _saveStem(song.drums, Stem.drums.value, songDirectory);
    song.other = await _saveStem(song.other, Stem.other.value, songDirectory);

    if (song.coverPath != null) {
      String newPath = p.join(songDirectory, p.basename(song.coverPath!));
      song.coverPath = (await File(song.coverPath!).move(newPath)).path;
    }

    return song;
  }

  /// Removes the song files from the file system.
  void removeSongFiles(UnmixedSong song) {
    File file = File(song.mixture);
    Directory directory = file.parent;
    directory.deleteSync(recursive: true);
  }
}
