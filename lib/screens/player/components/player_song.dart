import 'package:demixr_app/components/extended_widgets.dart';
import 'package:demixr_app/components/song.dart';
import 'package:demixr_app/utils.dart';
import 'package:flutter/material.dart';

class PlayerSong extends StatelessWidget {
  const PlayerSong({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SpacedColumn(
      spacing: 25,
      children: [
        Image.asset(
          getAssetPath('album_cover', AssetType.image),
          fit: BoxFit.contain,
          width: 200,
          height: 200,
        ),
        const SongInfos(
          'Electric Feel',
          'MGMT',
          alignCenter: true,
          size: 18,
        ),
      ],
    );
  }
}
