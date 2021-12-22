import 'package:demixr_app/constants.dart';
import 'package:demixr_app/screens/player/components/controller_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

import '../../../utils.dart';

class Controller extends StatelessWidget {
  const Controller({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    const radius = Radius.circular(35);
    return SizedBox(
      height: 125,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: ColorPalette.surfaceVariant,
          borderRadius: BorderRadius.only(topLeft: radius, topRight: radius),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ControllerButton(
              SvgPicture.asset(getAssetPath('previous', AssetType.icon)),
              gradient: ColorPalette.primaryFadedGradient,
              size: 55,
            ),
            ControllerButton(
              SvgPicture.asset(getAssetPath('play', AssetType.icon)),
            ),
            ControllerButton(
              SvgPicture.asset(getAssetPath('next', AssetType.icon)),
              gradient: ColorPalette.primaryFadedGradient,
              size: 55,
            ),
          ],
        ),
      ),
    );
  }
}
