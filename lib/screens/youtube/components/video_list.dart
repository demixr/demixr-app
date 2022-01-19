import 'package:dartz/dartz.dart';
import 'package:demixr_app/components/extended_widgets.dart';
import 'package:demixr_app/models/failure/no_album_cover.dart';
import 'package:demixr_app/screens/youtube/components/video_widget.dart';
import 'package:flutter/material.dart';

class VideoList extends StatelessWidget {
  const VideoList({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SpacedColumn(
      spacing: 10,
      children: [
        VideoWidget(
          title: 'Frank Ocean - Nikes',
          author: 'Blonded',
          coverPath: Left(NoAlbumCover()),
        )
      ],
    );
  }
}
