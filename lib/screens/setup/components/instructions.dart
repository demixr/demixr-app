import 'package:auto_size_text/auto_size_text.dart';
import 'package:demixr_app/components/extended_widgets.dart';
import 'package:demixr_app/constants.dart';
import 'package:flutter/material.dart';

class Instructions extends StatelessWidget {
  const Instructions({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SpacedColumn(
      spacing: 10,
      mainAxisAlignment: MainAxisAlignment.start,
      children: const [
        AutoSizeText(
          'First, select a model to separate your music',
          maxLines: 2,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.normal,
            color: ColorPalette.onSurface,
          ),
        ),
        Text(
          'You can always change this later in the settings',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            color: ColorPalette.onSurfaceVariant,
          ),
        )
      ],
    );
  }
}
