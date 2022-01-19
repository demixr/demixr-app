import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:demixr_app/components/extended_widgets.dart';
import 'package:demixr_app/constants.dart';
import 'package:demixr_app/models/failure/failure.dart';
import 'package:demixr_app/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

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
  final Either<Failure, String> imagePath;
  final double size;

  const Thumbnail({Key? key, required this.imagePath, this.size = 100})
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

class VideoWidget extends StatelessWidget {
  final String title;
  final String author;
  final Either<Failure, String> coverPath;
  final VoidCallback? onRemovePressed;
  final Color textColor;
  final bool download;

  const VideoWidget({
    Key? key,
    required this.title,
    required this.author,
    required this.coverPath,
    this.onRemovePressed,
    this.textColor = ColorPalette.onSurface,
    this.download = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    List<Widget> children = [
      SpacedRow(
        spacing: 15,
        children: [
          Thumbnail(imagePath: coverPath),
          VideoInfos(
            title: title,
            author: author,
            textColor: textColor,
          ),
        ],
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
