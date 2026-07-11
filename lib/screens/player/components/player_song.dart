import 'package:demixr_app/components/extended_widgets.dart';
import 'package:demixr_app/components/song_widget.dart';
import 'package:demixr_app/constants.dart';
import 'package:demixr_app/providers/library_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class PlayerSong extends StatelessWidget {
  final bool compact;

  const PlayerSong({super.key, this.compact = false});

  @override
  Widget build(BuildContext context) {
    return Consumer<LibraryProvider>(
      builder: (context, library, child) {
        final currentSong = library.currentSong;
        List<Widget> children = [];

        currentSong.fold((failure) {}, (song) {
          children = [
            AlbumCover(imagePath: song.albumCover, size: compact ? 180 : 280),
            SongInfos(
              title: song.title,
              artists: song.artists,
              alignCenter: true,
              size: compact ? 18 : 22,
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                color: ColorPalette.primary.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(100),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                child: Text(
                  song.modelName,
                  style: const TextStyle(
                    color: ColorPalette.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ];
        });

        return Center(
          child: SpacedColumn(
            spacing: compact ? 16 : 24,
            mainAxisSize: MainAxisSize.min,
            children: children,
          ),
        );
      },
    );
  }
}
