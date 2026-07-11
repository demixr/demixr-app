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
    super.key,
    required this.title,
    required this.author,
    required this.duration,
    this.size = 16,
    this.textColor = ColorPalette.onSurface,
  });

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
          spacing: 3,
          children: [
            Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: size,
                height: 1.2,
                color: textColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              author,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: size - 2,
                height: 1.2,
                color: textColor,
                fontWeight: FontWeight.w400,
              ),
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

  const Thumbnail({super.key, required this.imageUrl, this.size = 100});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: imageUrl.fold(
        (failure) => Image.asset(
          getAssetPath('default_cover', AssetType.image),
          fit: BoxFit.cover,
          width: size,
          height: size,
        ),
        (url) => Image.network(
          url,
          fit: BoxFit.cover,
          width: size,
          height: size,
          errorBuilder: (_, _, _) => Image.asset(
            getAssetPath('default_cover', AssetType.image),
            fit: BoxFit.cover,
            width: size,
            height: size,
          ),
        ),
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
    super.key,
    required this.title,
    required this.author,
    required this.coverUrl,
    required this.url,
    required this.duration,
    this.onRemovePressed,
    this.textColor = ColorPalette.onSurface,
  });

  @override
  Widget build(BuildContext context) {
    Either<Failure, String> imageUrl = (coverUrl == null)
        ? Left(NoAlbumCover())
        : Right(coverUrl!);

    final youtubeProvider = context.read<YoutubeProvider>();
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
      child: Material(
        color: ColorPalette.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => youtubeProvider.download(url),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Thumbnail(imageUrl: imageUrl, size: 96),
                const SizedBox(width: 14),
                Expanded(
                  child: SizedBox(
                    height: 96,
                    child: VideoInfos(
                      title: title,
                      author: author,
                      textColor: textColor,
                      duration: duration,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.download_rounded, color: ColorPalette.primary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
