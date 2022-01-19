import 'package:dartz/dartz.dart';
import 'package:demixr_app/models/failure/no_album_cover.dart';
import 'package:demixr_app/providers/youtube_provider.dart';
import 'package:demixr_app/screens/youtube/components/video_widget.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../constants.dart';

class VideoList extends StatelessWidget {
  const VideoList({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<YoutubeProvider>(
      builder: (context, youtube, child) {
        return ListView.builder(
          padding: const EdgeInsets.all(0),
          itemCount: youtube.videos.length,
          itemBuilder: (context, index) {
            final item = youtube.videos.elementAt(index);

            return Card(
              color: ColorPalette.surfaceVariant,
              clipBehavior: Clip.antiAlias,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: VideoWidget(
                  title: item.title,
                  author: item.channelTitle,
                  coverUrl: item.thumbnail.medium.url,
                ),
              ),
            );
          },
        );
      },
    );
  }
}
