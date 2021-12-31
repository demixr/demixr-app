import 'dart:io';
import 'package:demixr_app/models/song.dart';
import 'package:demixr_app/models/unmixed_song.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import '../utils.dart' show moveFile;
import '../constants.dart' show BoxesNames;

class LibraryRepository {
  final _box = Hive.box<UnmixedSong>(BoxesNames.library);
  final _directoryName = 'library';

  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  Future<String> get _directoryPath async {
    final path = await _localPath;
    var directory = Directory(p.join(path, _directoryName));

    if (await directory.exists()) {
      return directory.path;
    } else {
      directory = await directory.create(recursive: true);
      return directory.path;
    }
  }

  Future<Song> saveFile(Song song) async {
    String libraryDirectory = await _directoryPath;
    String filename = "${song}_mixture${p.extension(song.path)}";
    String songPath = p.join(libraryDirectory, filename);

    final savedFile = await moveFile(File(song.path), songPath);
    song.path = savedFile.path;

    return song;
  }

  void add(UnmixedSong song) {
    _box.add(song);
  }
}
