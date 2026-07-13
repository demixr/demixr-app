import 'package:demixr_app/constants.dart';
import 'package:demixr_app/providers/player_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class StemSelection extends StatelessWidget {
  const StemSelection({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<PlayerProvider>(
      builder: (context, player, child) {
        final stems = player.stems;
        return DecoratedBox(
          decoration: BoxDecoration(
            color: ColorPalette.surfaceContainer,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: ColorPalette.outline),
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'STEMS',
                  style: TextStyle(
                    color: ColorPalette.onSurfaceVariant,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.4,
                  ),
                ),
                const SizedBox(height: 12),
                for (final stem in stems) ...[
                  StemButton(stem),
                  if (stem != stems.last) const SizedBox(height: 8),
                ],
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
        final isMuted = player.isStemMute(stem);
        final volume = player.stemVolume(stem);

        return LayoutBuilder(
          builder: (context, constraints) {
            void updateVolume(double x) => player.setStemVolume(
              stem,
              (x / constraints.maxWidth).clamp(0.0, 1.0),
            );

            return Semantics(
              label: '${stem.name} volume',
              value: isMuted ? 'Muted' : '${(volume * 100).round()} percent',
              slider: true,
              increasedValue: '${((volume + .1).clamp(0, 1) * 100).round()}%',
              decreasedValue: '${((volume - .1).clamp(0, 1) * 100).round()}%',
              onIncrease: () =>
                  player.setStemVolume(stem, (volume + .1).clamp(0, 1)),
              onDecrease: () =>
                  player.setStemVolume(stem, (volume - .1).clamp(0, 1)),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  height: 52,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      ColoredBox(color: ColorPalette.surfaceContainerHigh),
                      FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: volume,
                        child: ColoredBox(
                          color: ColorPalette.primary.withValues(alpha: .34),
                        ),
                      ),
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTapDown: (details) =>
                            updateVolume(details.localPosition.dx),
                        onHorizontalDragUpdate: (details) =>
                            updateVolume(details.localPosition.dx),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 58, 0),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              stem.name,
                              style: TextStyle(
                                color: isMuted
                                    ? ColorPalette.onSurfaceVariant
                                    : ColorPalette.onSurface,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Semantics(
                          button: true,
                          label: isMuted
                              ? 'Unmute ${stem.name}'
                              : 'Mute ${stem.name}',
                          child: Tooltip(
                            message: isMuted ? 'Unmute stem' : 'Mute stem',
                            child: InkWell(
                              onTap: () => player.toggleStem(stem),
                              child: SizedBox(
                                width: 52,
                                height: 52,
                                child: Icon(
                                  isMuted
                                      ? Icons.volume_off_rounded
                                      : Icons.volume_up_rounded,
                                  size: 20,
                                  color: isMuted
                                      ? ColorPalette.onSurfaceVariant
                                      : ColorPalette.tertiary,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
