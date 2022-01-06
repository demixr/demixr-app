import 'package:dartz/dartz.dart';
import 'package:demixr_app/components/buttons.dart';
import 'package:demixr_app/models/failure/failure.dart';
import 'package:demixr_app/models/song.dart';
import 'package:demixr_app/providers/demixing_provider.dart';
import 'package:demixr_app/providers/library_provider.dart';
import 'package:demixr_app/providers/song_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

import '../../../constants.dart';
import '../../../utils.dart';

class UnmixButton extends StatelessWidget {
  const UnmixButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<SongProvider>(
      builder: (context, songProvider, child) {
        Either<Failure, Song> song = songProvider.song;

        return Button(
          'Unmix',
          icon: SvgPicture.asset(getAssetPath('rocket', AssetType.icon)),
          color: ColorPalette.tertiary,
          textColor: ColorPalette.onTertiary,
          padding:
              const EdgeInsets.only(left: 100, top: 25, right: 100, bottom: 25),
          radius: 25,
          textSize: 18,
          onPressed: song.fold(
            (failure) => null,
            (song) => () {
              var demixingProvider = context.read<DemixingProvider>();
              var library = context.read<LibraryProvider>();

              demixingProvider
                  .unmix(song)
                  ?.then((unmixed) => library.saveSong(unmixed))
                  .then(
                (index) {
                  library.setCurrentSongIndex(index);
                  Get.offNamed('/player');
                },
              );
            },
          ),
        );
      },
    );
  }
}
