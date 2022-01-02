import 'package:demixr_app/components/extended_widgets.dart';
import 'package:demixr_app/components/song_widget.dart';
import 'package:demixr_app/providers/library_provider.dart';
import 'package:demixr_app/utils.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class PlayerSong extends StatelessWidget {
  const PlayerSong({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    const double imageSize = 200;
    return Consumer<LibraryProvider>(
      builder: (context, library, child) {
        final currentSong = library.currentSong;
        return SpacedColumn(
          spacing: 25,
          children: [
            Image.asset(
              getAssetPath('album_cover', AssetType.image),
              fit: BoxFit.contain,
              width: imageSize,
              height: imageSize,
            ),
            SongInfos(
              title: currentSong.fold(
                  (l) => l.message, (song) => song.mixture.title),
              artists: currentSong.fold(
                  (l) => [l.message], (song) => song.mixture.artists),
              alignCenter: true,
              size: 18,
            ),
          ],
        );
      },
    );
  }
}
