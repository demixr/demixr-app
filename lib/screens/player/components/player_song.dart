import 'dart:typed_data';

import 'package:dartz/dartz.dart';
import 'package:demixr_app/components/extended_widgets.dart';
import 'package:demixr_app/components/song_widget.dart';
import 'package:demixr_app/models/failure/failure.dart';
import 'package:demixr_app/models/failure/no_album_cover.dart';
import 'package:demixr_app/providers/library_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../helpers/song_helper.dart';

class PlayerSong extends StatelessWidget {
  const PlayerSong({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    const double imageSize = 200;
    return Consumer<LibraryProvider>(
      builder: (context, library, child) {
        final currentSong = library.currentSong;
        List<Widget> children = [];

        currentSong.fold(
          (failure) {},
          (song) {
            children = [
              FutureBuilder<Either<Failure, Uint8List>>(
                future: song.mixture.albumCover,
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    return AlbumCover(
                      image: snapshot.data!,
                      size: imageSize,
                    );
                  } else {
                    return AlbumCover(
                      image: Left(NoAlbumCover()),
                      size: imageSize,
                    );
                  }
                },
              ),
              SongInfos(
                title: song.mixture.title,
                artists: song.mixture.artists,
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
