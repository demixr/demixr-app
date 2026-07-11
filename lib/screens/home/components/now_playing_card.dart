import 'package:demixr_app/components/song_widget.dart';
import 'package:demixr_app/constants.dart';
import 'package:demixr_app/providers/library_provider.dart';
import 'package:demixr_app/providers/player_provider.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

class NowPlayingCard extends StatelessWidget {
  final bool compact;

  const NowPlayingCard({super.key, this.compact = false});

  @override
  Widget build(BuildContext context) {
    return Consumer2<LibraryProvider, PlayerProvider>(
      builder: (context, library, player, child) {
        return library.currentSong.fold(
          (_) => compact ? const SizedBox.shrink() : const _EmptyPlayerCard(),
          (song) => DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  ColorPalette.primary.withValues(alpha: 0.22),
                  ColorPalette.primaryGradient.last.withValues(alpha: 0.16),
                ],
              ),
              borderRadius: BorderRadius.circular(compact ? 18 : 24),
              border: Border.all(
                color: ColorPalette.primary.withValues(alpha: 0.34),
              ),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(compact ? 18 : 24),
              onTap: () => Get.toNamed('/player'),
              child: Padding(
                padding: EdgeInsets.all(compact ? 12 : 18),
                child: compact
                    ? Row(
                        children: [
                          AlbumCover(imagePath: song.albumCover, size: 54),
                          const SizedBox(width: 12),
                          Expanded(child: _SongLabel(song.title, song.artists)),
                          _PlayButton(player: player, compact: true),
                        ],
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'NOW PLAYING',
                            style: TextStyle(
                              color: ColorPalette.primary,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.4,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              AlbumCover(imagePath: song.albumCover, size: 72),
                              const SizedBox(width: 14),
                              Expanded(
                                child: _SongLabel(song.title, song.artists),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              IconButton(
                                tooltip: 'Previous',
                                onPressed: player.previous,
                                icon: const Icon(Icons.skip_previous_rounded),
                              ),
                              const SizedBox(width: 8),
                              _PlayButton(player: player),
                              const SizedBox(width: 8),
                              IconButton(
                                tooltip: 'Next',
                                onPressed: player.next,
                                icon: const Icon(Icons.skip_next_rounded),
                              ),
                            ],
                          ),
                        ],
                      ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SongLabel extends StatelessWidget {
  final String title;
  final List<String> artists;

  const _SongLabel(this.title, this.artists);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        Text(
          artists.join(', '),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: ColorPalette.onSurfaceVariant),
        ),
      ],
    );
  }
}

class _PlayButton extends StatelessWidget {
  final PlayerProvider player;
  final bool compact;

  const _PlayButton({required this.player, this.compact = false});

  @override
  Widget build(BuildContext context) {
    return IconButton.filled(
      tooltip: player.isPlaying ? 'Pause' : 'Play',
      style: IconButton.styleFrom(
        backgroundColor: ColorPalette.primary,
        foregroundColor: ColorPalette.onPrimary,
        minimumSize: Size.square(compact ? 42 : 50),
      ),
      onPressed: player.playpause,
      icon: Icon(
        player.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
      ),
    );
  }
}

class _EmptyPlayerCard extends StatelessWidget {
  const _EmptyPlayerCard();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: ColorPalette.surfaceContainer,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: ColorPalette.outline),
      ),
      child: const Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.graphic_eq_rounded, color: ColorPalette.primary),
            SizedBox(height: 12),
            Text(
              'Nothing playing yet',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            SizedBox(height: 4),
            Text(
              'Choose a song from your library to start listening.',
              style: TextStyle(color: ColorPalette.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
