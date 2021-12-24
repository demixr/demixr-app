import 'dart:io';

import 'dart:typed_data';

class Song {
  final String? title;
  final List<String>? artists;
  final File file;
  final Uint8List? cover;

  Song({this.title, this.artists, required this.file, this.cover});
}
