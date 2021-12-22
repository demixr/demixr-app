// import 'package:demixr_app/components/buttons.dart';
import 'package:demixr_app/components/buttons.dart';
import 'package:demixr_app/components/navbar.dart';
import 'package:demixr_app/components/page_title.dart';
import 'package:demixr_app/utils.dart';
// import 'package:demixr_app/components/page_title.dart';
// import 'package:demixr_app/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

import '../../constants.dart';
import 'components/song_selection.dart';
// import 'package:flutter_svg/flutter_svg.dart';

class DemixingScreen extends StatelessWidget {
  const DemixingScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        height: double.maxFinite,
        width: double.maxFinite,
        margin: const EdgeInsets.all(10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            const NavBar(),
            const SizedBox(height: 20),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const PageTitle('Demixing'),
                  const SongSelection(),
                  Button(
                    'Unmix',
                    icon: SvgPicture.asset(
                        getAssetPath('rocket', AssetType.icon)),
                    color: ColorPalette.tertiary,
                    textColor: ColorPalette.onTertiary,
                    padding: const EdgeInsets.only(
                        left: 100, top: 25, right: 100, bottom: 25),
                    radius: 25,
                    textSize: 18,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
