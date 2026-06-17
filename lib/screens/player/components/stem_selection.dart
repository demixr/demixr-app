import 'package:demixr_app/components/buttons.dart';
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
        // 4 stems stack one per row; 6 lay out two per row so the player stays
        // compact. Each cell is Expanded, so buttons share the width evenly and
        // never overflow regardless of window size.
        final perRow = stems.length > 4 ? 2 : 1;

        final rows = <Widget>[];
        for (var i = 0; i < stems.length; i += perRow) {
          final rowStems = stems.skip(i).take(perRow).toList();
          rows.add(
            Row(
              children: [
                for (final stem in rowStems)
                  Expanded(child: StemButton(stem)),
                // Keep the last odd cell aligned with the column above it.
                for (var pad = rowStems.length; pad < perRow; pad++)
                  const Expanded(child: SizedBox.shrink()),
              ],
            ),
          );
        }

        return DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.all(radius),
            border: Border.all(width: 2, color: ColorPalette.surfaceVariant),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Column(mainAxisSize: MainAxisSize.min, children: rows),
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
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: ColorPalette.onSurface),
              const SizedBox(width: 8),
              Flexible(
                child: Button(
                  stem.name,
                  color: ColorPalette.inverseSurface,
                  textColor: ColorPalette.inversePrimary,
                  textSize: 16,
                  radius: 12,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 15,
                    vertical: 5,
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
