import 'dart:io';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:dartz/dartz.dart';
import 'package:demixr_app/constants.dart';
import 'package:demixr_app/models/failure/failure.dart';
import 'package:demixr_app/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'extended_widgets.dart';

class SongInfos extends StatelessWidget {
  final String title;
  final List<String> artists;
  final double size;
  final bool alignCenter;
  final Color textColor;

  const SongInfos({
    Key? key,
    required this.title,
    required this.artists,
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
        AutoSizeText(
          title,
          textAlign: alignCenter ? TextAlign.center : TextAlign.left,
          maxLines: 2,
          minFontSize: 10,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
              fontSize: size, color: textColor, fontWeight: FontWeight.w600),
        ),
        AutoSizeText(
          artists.join(', '),
          textAlign: alignCenter ? TextAlign.center : TextAlign.left,
          maxLines: 1,
          minFontSize: 8,
          style: TextStyle(
              fontSize: size - 2,
              color: textColor,
              fontWeight: FontWeight.w400),
        ),
      ],
    );
  }
}

class AlbumCover extends StatelessWidget {
  final Either<Failure, String> imagePath;
  final double? size;

  const AlbumCover({Key? key, required this.imagePath, this.size = 65})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return imagePath.fold(
      (failure) => Image.asset(
        getAssetPath('default_cover', AssetType.image),
        fit: BoxFit.contain,
        width: size,
        height: size,
      ),
      (coverPath) => Image.file(
        File(coverPath),
        fit: BoxFit.cover,
        width: size,
        height: size,
      ),
    );
  }
}

class SongWidget extends StatelessWidget {
  final String title;
  final List<String> artists;
  final Either<Failure, String> coverPath;
  final VoidCallback? onRemovePressed;
  final Color textColor;
  final bool download;

  const SongWidget({
    Key? key,
    required this.title,
    required this.artists,
    required this.coverPath,
    this.onRemovePressed,
    this.textColor = ColorPalette.onSurface,
    this.download = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    List<Widget> children = [
      Expanded(
        child: SpacedRow(
          spacing: 15,
          children: [
            AlbumCover(imagePath: coverPath),
            Expanded(
              child: SongInfos(
                title: title,
                artists: artists,
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
            strokeWidth: 4,
          )));
    } else {
      children.add(
        PopupMenuButton(
          padding: const EdgeInsets.all(0),
          color: ColorPalette.surfaceVariant,
          icon: SvgPicture.asset(
            getAssetPath('dots', AssetType.icon),
          ),
          itemBuilder: (context) => [
            PopupMenuItem(
              child: SpacedRow(
                spacing: 5,
                children: const [
                  Icon(
                    Icons.delete,
                    color: ColorPalette.onSurfaceVariant,
                  ),
                  Text("Remove"),
                ],
              ),
              onTap: onRemovePressed,
            ),
          ],
        ),
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: children,
    );
  }
}
