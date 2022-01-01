import 'dart:typed_data';

import 'package:dartz/dartz.dart';
import 'package:demixr_app/components/buttons.dart';
import 'package:demixr_app/components/extended_widgets.dart';
import 'package:demixr_app/components/song_widget.dart';
import 'package:demixr_app/constants.dart';
import 'package:demixr_app/models/failure/failure.dart';
import 'package:demixr_app/models/song.dart';
import 'package:demixr_app/providers/song_provider.dart';
import 'package:demixr_app/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

class SongSelection extends StatelessWidget {
  const SongSelection({Key? key}) : super(key: key);

  Widget buildButtons(SongProvider provider) => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Button(
            'Youtube link',
            icon: Icon(
              Icons.file_upload,
              color: ColorPalette.onPrimary,
              size: 18,
            ),
            textSize: 16,
          ),
          const SizedBox(width: 10),
          Button(
            'Browse files',
            icon: SvgPicture.asset(
              getAssetPath('youtube', AssetType.icon),
            ),
            textSize: 16,
            onPressed: provider.loadFromDevice,
          ),
        ],
      );

  Widget buildSelectionCard(SongProvider provider) => Card(
        color: ColorPalette.surfaceVariant,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.only(top: 20, bottom: 20),
          child: SpacedColumn(
            spacing: 30,
            children: [
              const ListTile(
                title: Text(
                  'Song selection',
                  style: TextStyle(
                      color: ColorPalette.primary,
                      fontSize: 22,
                      fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center,
                ),
              ),
              const Text(
                'You can select a song from your device or directly from Youtube.',
                style: TextStyle(
                    color: ColorPalette.onSurfaceVariant, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              buildButtons(provider),
            ],
          ),
        ),
      );

  Widget buildSelectedSongCard(Song song, Either<Failure, Uint8List> cover) =>
      Card(
        color: ColorPalette.surfaceVariant,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: SongWidget(
            title: song.title,
            artists: song.artists,
            cover: cover,
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Consumer<SongProvider>(
      builder: (context, songProvider, child) {
        Either<Failure, Song> song = songProvider.song;
        List<Widget> children = [buildSelectionCard(songProvider)];

        // Add the song card if a song is selected
        song.fold(
          (failure) => null,
          (song) =>
              children.add(buildSelectedSongCard(song, songProvider.cover)),
        );

        return Column(
          children: children,
        );
      },
    );
  }
}
