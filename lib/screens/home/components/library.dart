import 'package:dartz/dartz.dart';
import 'package:demixr_app/components/song_widget.dart';
import 'package:demixr_app/constants.dart';
import 'package:demixr_app/models/failure/failure.dart';
import 'package:demixr_app/models/unmixed_song.dart';
import 'package:demixr_app/providers/library_provider.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

import '../../../utils.dart';

class Library extends StatelessWidget {
  const Library({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Library',
            style: TextStyle(color: ColorPalette.onSurface, fontSize: 36),
          ),
          Expanded(
            child: Consumer<LibraryProvider>(
              builder: (context, library, child) {
                return library.isEmpty
                    ? const EmptyLibrary()
                    : const LibrarySongs();
              },
            ),
          ),
        ],
      ),
    );
  }
}

class LibrarySongs extends StatelessWidget {
  const LibrarySongs({Key? key}) : super(key: key);

  Widget buildSongButton(SongWidget song, {VoidCallback? onPressed}) =>
      TextButton(
        onPressed: onPressed,
        child: song,
        style: TextButton.styleFrom(
            padding:
                const EdgeInsets.only(left: 2, top: 5, right: 2, bottom: 5)),
      );

  bool isSongSelected(UnmixedSong song, Either<Failure, UnmixedSong> selected) {
    return selected.fold(
      (failure) => false,
      (selectedSong) => song == selectedSong,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LibraryProvider>(
      builder: (context, library, child) {
        return ListView.builder(
          padding: const EdgeInsets.all(0),
          itemCount: library.numberOfSongs,
          itemBuilder: (context, index) {
            // sort from newest to oldest
            index = library.getIndexByOrder(index);
            final currentSong = library.getAt(index);

            final infosColor = library.matchSelectedSong(index)
                ? ColorPalette.primary
                : ColorPalette.onSurface;

            return buildSongButton(
              SongWidget(
                title: currentSong.title,
                artists: currentSong.artists,
                coverPath: currentSong.albumCover,
                textColor: infosColor,
                onRemovePressed: () {
                  library.removeSong(index);
                  Get.snackbar(
                    'Demixr',
                    '${currentSong.title} was removed from library',
                    backgroundColor: ColorPalette.primary,
                    colorText: ColorPalette.onPrimary,
                    animationDuration: const Duration(milliseconds: 500),
                  );
                },
              ),
              onPressed: () {
                library.setCurrentSongIndex(index);
                Get.toNamed('player');
              },
            );
          },
        );
      },
    );
  }
}

class EmptyLibrary extends StatelessWidget {
  const EmptyLibrary({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          child: Image.asset(getAssetPath('astronaut', AssetType.image)),
        ),
        const SizedBox(
          width: 200,
          child: Text(
            'Your library is empty at the moment',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              color: ColorPalette.onSurface,
            ),
          ),
        ),
      ],
    );
  }
}
