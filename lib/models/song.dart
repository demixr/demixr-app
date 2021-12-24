import 'dart:io';

import 'dart:typed_data';

class Song {
  final String title;
  final List<String> artists;
  final Uint8List? cover;

  Song({required this.title, required this.artists, this.cover});
}
