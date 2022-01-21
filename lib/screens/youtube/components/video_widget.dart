import 'package:dartz/dartz.dart';
import 'package:demixr_app/components/extended_widgets.dart';
import 'package:demixr_app/constants.dart';
import 'package:demixr_app/models/failure/failure.dart';
import 'package:demixr_app/models/failure/no_album_cover.dart';
import 'package:demixr_app/providers/youtube_provider.dart';
import 'package:demixr_app/utils.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class VideoInfos extends StatelessWidget {
  final String title;
  final String author;
  final Duration? duration;
  final double size;
  final Color textColor;

  const VideoInfos({
    Key? key,
    required this.title,
    required this.author,
    required this.duration,
    this.size = 16,
    this.textColor = ColorPalette.onSurface,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Widget durationText = duration != null
        ? Text(
            duration!.formatMinSec(),
            style: TextStyle(
              fontSize: size - 2,
              color: textColor,
              fontWeight: FontWeight.w600,
            ),
          )
        : const SizedBox.shrink();

    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SpacedColumn(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 5,
          children: [
            Text(
              title,
              style: TextStyle(
                  fontSize: size,
                  color: textColor,
                  fontWeight: FontWeight.w600),
            ),
            Text(
              author,
              style: TextStyle(
                  fontSize: size - 2,
                  color: textColor,
                  fontWeight: FontWeight.w400),
            ),
          ],
        ),
        durationText,
      ],
    );
  }
}

class Thumbnail extends StatelessWidget {
  final Either<Failure, String> imageUrl;
  final double size;

  const Thumbnail({Key? key, required this.imageUrl, this.size = 100})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return imageUrl.fold(
      (failure) => Image.asset(
        getAssetPath('default_cover', AssetType.image),
        fit: BoxFit.contain,
        width: size,
        height: size,
      ),
      (url) => Image.network(
        url,
        fit: BoxFit.cover,
        width: size,
        height: size,
      ),
    );
  }
}

class VideoWidget extends StatelessWidget {
  final String title;
  final String author;
  final String? coverUrl;
  final String url;
  final Duration? duration;
  final VoidCallback? onRemovePressed;
  final Color textColor;

  const VideoWidget({
    Key? key,
    required this.title,
    required this.author,
    required this.coverUrl,
    required this.url,
    required this.duration,
    this.onRemovePressed,
    this.textColor = ColorPalette.onSurface,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Either<Failure, String> imageUrl =
        (coverUrl == null) ? Left(NoAlbumCover()) : Right(coverUrl!);

    List<Widget> children = [
      Expanded(
        child: IntrinsicHeight(
          child: SpacedRow(
            spacing: 15,
            children: [
              Thumbnail(imageUrl: imageUrl),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 5, bottom: 5),
                  child: VideoInfos(
                    title: title,
                    author: author,
                    textColor: textColor,
                    duration: duration,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ];

    final youtubeProvider = context.read<YoutubeProvider>();
    return TextButton(
      onPressed: () => youtubeProvider.download(url),
      style: TextButton.styleFrom(padding: const EdgeInsets.all(0)),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: children,
        ),
      ),
    );
  }
}
