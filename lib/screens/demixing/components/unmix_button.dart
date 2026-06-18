import 'package:demixr_app/components/buttons.dart';
import 'package:demixr_app/providers/demixing_provider.dart';
import 'package:demixr_app/providers/library_provider.dart';
import 'package:demixr_app/providers/song_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';

import '../../../constants.dart';
import '../../../utils.dart';

class UnmixButton extends StatelessWidget {
  const UnmixButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SongProvider>(
      builder: (context, songProvider, child) {
        return Button(
          'Unmix',
          icon: SvgPicture.asset(getAssetPath('rocket', AssetType.icon)),
          color: ColorPalette.tertiary,
          textColor: ColorPalette.onTertiary,
          padding: const EdgeInsets.all(25),
          textSize: 18,
          onPressed: songProvider.song.fold(
            (failure) => () {
              errorSnackbar(
                'No song selected',
                'You need to select a song first',
              );
            },
            (song) => () {
              var demixingProvider = context.read<DemixingProvider>();
              var library = context.read<LibraryProvider>();

              demixingProvider.unmix(song, library);
            },
          ),
        );
      },
    );
  }
}
