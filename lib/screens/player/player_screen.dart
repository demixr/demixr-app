import 'package:demixr_app/components/navbar.dart';
import 'package:demixr_app/screens/player/components/controller.dart';
import 'package:demixr_app/screens/player/components/player_song.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

import '../../utils.dart';

class PlayerScreen extends StatelessWidget {
  const PlayerScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        height: double.maxFinite,
        width: double.maxFinite,
        margin: const EdgeInsets.only(left: 10, top: 10, right: 10),
        child: Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              NavBar(
                extra: [
                  IconButton(
                    onPressed: () {},
                    icon: SvgPicture.asset(
                      getAssetPath('dots', AssetType.icon),
                    ),
                  ),
                ],
              ),
              const PlayerSong(),
              const Controller(),
            ],
          ),
        ),
      ),
    );
  }
}
