import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:demixr_app/constants.dart';
import 'package:demixr_app/providers/player_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SongProgressBar extends StatelessWidget {
  const SongProgressBar({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final player = context.read<PlayerProvider>();
    return FutureBuilder<int>(
      future: player.songDuration,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          final songDuration = snapshot.data!;

          return StreamBuilder<Duration>(
            stream: player.positionStream,
            builder: (context, snapshot) {
              final position = snapshot.data;
              final progress = position ?? player.position;
              final total = Duration(milliseconds: songDuration);

              return ProgressBar(
                progress: progress,
                total: total,
                progressBarColor: ColorPalette.inverseSurface,
                baseBarColor: Colors.white.withOpacity(0.2),
                barHeight: 3,
                thumbRadius: 5,
                thumbColor: ColorPalette.inverseSurface,
                thumbGlowRadius: 12,
                timeLabelTextStyle:
                    const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                onSeek: (duration) {
                  player.seek(duration);
                },
              );
            },
          );
        } else {
          // return an empty widget
          return const SizedBox.shrink();
        }
      },
    );
  }
}
