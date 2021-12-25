import 'package:demixr_app/components/buttons.dart';
import 'package:demixr_app/models/song.dart';
import 'package:demixr_app/providers/song_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';

import '../../../constants.dart';
import '../../../utils.dart';

class UnmixButton extends StatelessWidget {
  const UnmixButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var songSelected = context.select<SongProvider, bool>(
      (provider) => provider.song.isRight(),
    );
    print('IS A SONG SELECTED: $songSelected');

    return Button(
      'Unmix',
      icon: SvgPicture.asset(getAssetPath('rocket', AssetType.icon)),
      color: ColorPalette.tertiary,
      textColor: ColorPalette.onTertiary,
      padding:
          const EdgeInsets.only(left: 100, top: 25, right: 100, bottom: 25),
      radius: 25,
      textSize: 18,
      onPressed: songSelected
          ? () {
              var songProvider = context.read<SongProvider>();
              songProvider.unmixSong();
            }
          : null,
    );
  }
}
