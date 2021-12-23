import 'package:demixr_app/constants.dart';
import 'package:demixr_app/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'extended_widgets.dart';

class SongInfos extends StatelessWidget {
  final String name;
  final String artist;
  final double size;
  final bool alignCenter;

  const SongInfos(this.name, this.artist,
      {Key? key, this.size = 16, this.alignCenter = false})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SpacedColumn(
      spacing: 5,
      crossAxisAlignment:
          alignCenter ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        Text(
          name,
          style: TextStyle(
              fontSize: size,
              color: ColorPalette.onSurface,
              fontWeight: FontWeight.w600),
        ),
        Text(
          artist,
          style: TextStyle(
              fontSize: size - 2,
              color: ColorPalette.onSurface,
              fontWeight: FontWeight.w400),
        ),
      ],
    );
  }
}

class Song extends StatelessWidget {
  const Song({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        SpacedRow(
          spacing: 15,
          children: [
            Image.asset(
              getAssetPath('album_cover', AssetType.image),
              fit: BoxFit.contain,
              width: 65,
              height: 65,
            ),
            const SongInfos('Electric Feel', 'MGMT')
          ],
        ),
        IconButton(
          onPressed: () {},
          icon: SvgPicture.asset(
            getAssetPath('dots', AssetType.icon),
          ),
        ),
      ],
    );
  }
}
