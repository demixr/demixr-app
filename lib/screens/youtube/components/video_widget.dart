import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:demixr_app/components/extended_widgets.dart';
import 'package:demixr_app/constants.dart';
import 'package:demixr_app/models/failure/failure.dart';
import 'package:demixr_app/models/failure/no_album_cover.dart';
import 'package:demixr_app/utils.dart';
import 'package:flutter/material.dart';

class VideoInfos extends StatelessWidget {
  final String title;
  final String author;
  final double size;
  final bool alignCenter;
  final Color textColor;

  const VideoInfos({
    Key? key,
    required this.title,
    required this.author,
    this.size = 16,
    this.alignCenter = false,
    this.textColor = ColorPalette.onSurface,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SpacedColumn(
      spacing: 5,
      crossAxisAlignment:
          alignCenter ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
              fontSize: size, color: textColor, fontWeight: FontWeight.w600),
        ),
        Text(
          author,
          style: TextStyle(
              fontSize: size - 2,
              color: textColor,
              fontWeight: FontWeight.w400),
        ),
      ],
    );
  }
}

class Thumbnail extends StatelessWidget {
  final Either<Failure, String> imageUrl;
  final double size;

  const Thumbnail({Key? key, required this.imageUrl, this.size = 120})
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
  final VoidCallback? onRemovePressed;
  final Color textColor;
  final bool download;

  const VideoWidget({
    Key? key,
    required this.title,
    required this.author,
    required this.coverUrl,
    this.onRemovePressed,
    this.textColor = ColorPalette.onSurface,
    this.download = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Either<Failure, String> imageUrl =
        (coverUrl == null) ? Left(NoAlbumCover()) : Right(coverUrl!);

    List<Widget> children = [
      Expanded(
        child: SpacedRow(
          spacing: 15,
          children: [
            Thumbnail(imageUrl: imageUrl),
            Expanded(
              child: VideoInfos(
                title: title,
                author: author,
                textColor: textColor,
              ),
            ),
          ],
        ),
      ),
    ];

    if (download) {
      children.add(const Padding(
          padding: EdgeInsets.all(10),
          child: CircularProgressIndicator(
            color: ColorPalette.primary,
            strokeWidth: 5,
          )));
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: children,
    );
  }
}
