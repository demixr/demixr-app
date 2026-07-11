import 'package:demixr_app/components/navbar.dart';
import 'package:demixr_app/constants.dart';
import 'package:demixr_app/screens/player/components/controller.dart';
import 'package:demixr_app/screens/player/components/infos_dialog.dart';
import 'package:demixr_app/screens/player/components/player_song.dart';
import 'package:demixr_app/screens/player/components/stem_selection.dart';
import 'package:flutter/material.dart';

class PlayerScreen extends StatelessWidget {
  const PlayerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isDesktop = constraints.maxWidth >= 760;
            final isCompactDesktop = constraints.maxWidth < 1050;
            final padding = isDesktop ? 20.0 : 12.0;

            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1280),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(padding, 8, padding, 16),
                  child: Column(
                    children: [
                      NavBar(
                        extra: [
                          IconButton(
                            tooltip: 'Song details',
                            onPressed: () => showDialog(
                              context: context,
                              builder: (context) => const InfosDialog(),
                            ),
                            icon: const Icon(Icons.info_outline_rounded),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: isDesktop
                            ? Row(
                                children: [
                                  Expanded(
                                    child: _PlayerPanel(
                                      compact: isCompactDesktop,
                                      child: PlayerSong(
                                        compact: isCompactDesktop,
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: isCompactDesktop ? 16 : 24),
                                  SizedBox(
                                    width: isCompactDesktop ? 360 : 440,
                                    child: Column(
                                      children: const [
                                        Expanded(child: StemSelection()),
                                        SizedBox(height: 18),
                                        SongController(),
                                      ],
                                    ),
                                  ),
                                ],
                              )
                            : LayoutBuilder(
                                builder: (context, viewport) {
                                  return FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.topCenter,
                                    child: SizedBox(
                                      width: viewport.maxWidth,
                                      child: const Column(
                                        children: [
                                          PlayerSong(compact: true),
                                          SizedBox(height: 16),
                                          StemSelection(),
                                          SizedBox(height: 10),
                                          SongController(),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _PlayerPanel extends StatelessWidget {
  final Widget child;
  final bool compact;

  const _PlayerPanel({required this.child, this.compact = false});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: ColorPalette.surfaceContainer,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: ColorPalette.outline),
      ),
      child: Padding(padding: EdgeInsets.all(compact ? 20 : 32), child: child),
    );
  }
}
