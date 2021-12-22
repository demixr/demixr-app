import 'package:demixr_app/constants.dart';
import 'package:demixr_app/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'extended_widgets.dart';

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
              getAssetPath('artist', AssetType.image),
              fit: BoxFit.contain,
              width: 65,
              height: 65,
            ),
            SpacedColumn(
              spacing: 5,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Electric Feel',
                  style: TextStyle(
                      fontSize: 16,
                      color: ColorPalette.onSurface,
                      fontWeight: FontWeight.w600),
                ),
                Text(
                  'MGMT',
                  style: TextStyle(
                      fontSize: 14,
                      color: ColorPalette.onSurface,
                      fontWeight: FontWeight.w400),
                ),
              ],
            ),
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
