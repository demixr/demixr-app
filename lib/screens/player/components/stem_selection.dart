import 'package:demixr_app/components/buttons.dart';
import 'package:demixr_app/components/extended_widgets.dart';
import 'package:demixr_app/constants.dart';
import 'package:demixr_app/providers/player_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class StemSelection extends StatelessWidget {
  const StemSelection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    const radius = Radius.circular(35);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.all(radius),
        border: Border.all(width: 2, color: ColorPalette.surfaceVariant),
      ),
      child: Padding(
        padding:
            const EdgeInsets.only(left: 20, top: 10, right: 20, bottom: 10),
        child: Column(
          children: const [
            StemButton(Stem.vocals),
            StemButton(Stem.bass),
            StemButton(Stem.drums),
            StemButton(Stem.other),
          ],
        ),
      ),
    );
  }
}

class StemButton extends StatelessWidget {
  final Stem stem;

  const StemButton(this.stem, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<PlayerProvider>(
      builder: (context, player, child) {
        final icon =
            player.isStemMute(stem) ? Icons.headset_off : Icons.headset;

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
                      left: 15, top: 5, right: 15, bottom: 5),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
