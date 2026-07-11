import 'package:demixr_app/constants.dart';
import 'package:demixr_app/providers/player_provider.dart';
import 'package:demixr_app/screens/player/components/controller_button.dart';
import 'package:demixr_app/screens/player/components/song_progress_bar.dart';
import 'package:demixr_app/screens/player/components/stem_selection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';

import '../../../utils.dart';

class Controller extends StatelessWidget {
  const Controller({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(children: [StemSelection(), SongController()]);
  }
}

class SongController extends StatelessWidget {
  const SongController({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 138,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: ColorPalette.surfaceContainer,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: ColorPalette.outline),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: SongProgressBar(),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ControllerButton(
                  SvgPicture.asset(getAssetPath('previous', AssetType.icon)),
                  gradient: ColorPalette.primaryFadedGradient,
                  size: 48,
                  onPressed: () => context.read<PlayerProvider>().previous(),
                ),
                Consumer<PlayerProvider>(
                  builder: (context, player, child) {
                    final icon = player.isPlaying
                        ? const Icon(Icons.pause, color: Colors.white, size: 35)
                        : SvgPicture.asset(
                            getAssetPath('play', AssetType.icon),
                          );

                    return ControllerButton(
                      icon,
                      size: 58,
                      onPressed: () => player.playpause(),
                    );
                  },
                ),
                ControllerButton(
                  SvgPicture.asset(getAssetPath('next', AssetType.icon)),
                  gradient: ColorPalette.primaryFadedGradient,
                  size: 48,
                  onPressed: () => context.read<PlayerProvider>().next(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
