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
  const Library({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Library', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 18),
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
    );
  }
}

class LibrarySongs extends StatelessWidget {
  const LibrarySongs({super.key});

  Widget buildSongButton(
    SongWidget song, {
    required String semanticsLabel,
    VoidCallback? onPressed,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Semantics(
      button: true,
      label: semanticsLabel,
      onTap: onPressed,
      excludeSemantics: true,
      child: Material(
        color: ColorPalette.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onPressed,
          child: Padding(padding: const EdgeInsets.all(12), child: song),
        ),
      ),
    ),
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
                modelName: currentSong.modelName,
                onRemovePressed: () {
                  library.removeSong(index);
                  Get.snackbar(
                    'Demixr',
                    '${currentSong.title} was removed from the library',
                    backgroundColor: ColorPalette.primary,
                    colorText: ColorPalette.onPrimary,
                    animationDuration: const Duration(milliseconds: 500),
                  );
                },
              ),
              semanticsLabel:
                  '${currentSong.title}, ${currentSong.artists.join(', ')}',
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
  const EmptyLibrary({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Flexible + BoxFit.contain so the illustration scales down to fit the
        // available height instead of overflowing on short/wide windows.
        Flexible(
          child: FractionallySizedBox(
            widthFactor: 0.6,
            child: Image.asset(
              getAssetPath('astronaut', AssetType.image),
              fit: BoxFit.contain,
            ),
          ),
        ),
        const SizedBox(height: 16),
        const FractionallySizedBox(
          widthFactor: 0.6,
          child: Text(
            'Your library is empty at the moment',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18, color: ColorPalette.onSurface),
          ),
        ),
      ],
    );
  }
}
