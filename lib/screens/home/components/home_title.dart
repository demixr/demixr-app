import 'package:auto_size_text/auto_size_text.dart';
import 'package:demixr_app/constants.dart';
import 'package:flutter/material.dart';

class HomeTitle extends StatelessWidget {
  const HomeTitle({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: const [
        AutoSizeText(
          'Demixr',
          style: TextStyle(
            fontSize: 72,
            fontWeight: FontWeight.normal,
            color: ColorPalette.primary,
          ),
          maxLines: 1,
        ),
        AutoSizeText(
          'Music demixing in your pocket',
          style: TextStyle(fontSize: 16),
          maxLines: 1,
        )
      ],
    );
  }
}
