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

        return Material(
          color: isMuted
              ? ColorPalette.surfaceContainerHigh
              : ColorPalette.primary.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => player.toggleStem(stem),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: isMuted
                          ? ColorPalette.onSurfaceVariant
                          : ColorPalette.tertiary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      stem.name,
                      style: TextStyle(
                        color: isMuted
                            ? ColorPalette.onSurfaceVariant
                            : ColorPalette.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Icon(
                    isMuted
                        ? Icons.volume_off_rounded
                        : Icons.volume_up_rounded,
                    size: 20,
                    color: isMuted
                        ? ColorPalette.onSurfaceVariant
                        : ColorPalette.tertiary,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
