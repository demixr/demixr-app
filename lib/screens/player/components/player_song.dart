import 'package:demixr_app/components/extended_widgets.dart';
import 'package:demixr_app/components/song_widget.dart';
import 'package:demixr_app/providers/library_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class PlayerSong extends StatelessWidget {
  const PlayerSong({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    const double? imageSize = 185;
    return Consumer<LibraryProvider>(
      builder: (context, library, child) {
        final currentSong = library.currentSong;
        List<Widget> children = [];

        currentSong.fold(
          (failure) {},
          (song) {
            children = [
              AlbumCover(
                imagePath: song.albumCover,
                size: imageSize,
              ),
              SongInfos(
                title: song.title,
                artists: song.artists,
                alignCenter: true,
                size: 18,
              ),
            ];
          },
        );

        return SpacedColumn(
          spacing: 25,
          children: children,
        );
      },
    );
  }
}
