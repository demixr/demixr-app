import 'package:auto_size_text/auto_size_text.dart';
import 'package:demixr_app/constants.dart';
import 'package:flutter/material.dart';

class SetupTitle extends StatelessWidget {
  const SetupTitle({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: const [
        AutoSizeText(
          'Welcome',
          maxLines: 1,
          style: TextStyle(
            fontSize: 80,
            fontWeight: FontWeight.normal,
            color: ColorPalette.primary,
          ),
        ),
        AutoSizeText(
          'to Demixr',
          maxLines: 1,
          style: TextStyle(
            fontSize: 48,
            color: ColorPalette.primary,
          ),
        ),
      ],
    );
  }
}
