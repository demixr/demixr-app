import 'package:demixr_app/components/buttons.dart';
import 'package:demixr_app/components/extended_widgets.dart';
import 'package:demixr_app/constants.dart';
import 'package:demixr_app/providers/player_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class StemSelection extends StatelessWidget {
  const StemSelection({super.key});

  @override
  Widget build(BuildContext context) {
    const radius = Radius.circular(35);
    return Consumer<PlayerProvider>(
      builder: (context, player, child) {
        final stems = player.stems;
        // 4 stems fit in one column; 6 lay out as two columns so the player
        // stays compact and scroll-free.
        final twoColumns = stems.length > 4;
        return DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.all(radius),
            border: Border.all(width: 2, color: ColorPalette.surfaceVariant),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: 10,
              runSpacing: 4,
              children: [
                for (final stem in stems)
                  SizedBox(
                    width: twoColumns ? 150 : double.infinity,
                    child: StemButton(stem),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class StemButton extends StatelessWidget {
  final Stem stem;

  const StemButton(this.stem, {super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<PlayerProvider>(
      builder: (context, player, child) {
        final icon = player.isStemMute(stem)
            ? Icons.headset_off
            : Icons.headset;

        return TextButton(
          style: TextButton.styleFrom(padding: const EdgeInsets.all(0)),
          onPressed: () => player.toggleStem(stem),
          child: SpacedRow(
            spacing: 10,
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: ColorPalette.onSurface),
              SizedBox(
                width: 125,
                child: Button(
                  stem.name,
                  color: ColorPalette.inverseSurface,
                  textColor: ColorPalette.inversePrimary,
                  textSize: 16,
                  radius: 12,
                  padding: const EdgeInsets.only(
                    left: 15,
                    top: 5,
                    right: 15,
                    bottom: 5,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
