import 'package:demixr_app/components/buttons.dart';
import 'package:demixr_app/components/extended_widgets.dart';
import 'package:demixr_app/constants.dart';
import 'package:flutter/material.dart';

class StemSelection extends StatelessWidget {
  const StemSelection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    const radius = Radius.circular(35);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.all(radius),
        border: Border.all(width: 2, color: ColorPalette.surfaceVariant),
      ),
      child: Padding(
        padding:
            const EdgeInsets.only(left: 20, top: 10, right: 20, bottom: 10),
        child: Column(
          children: const [
            StemButton('Vocals', isActivated: false),
            StemButton('Bass', isActivated: true),
            StemButton('Drums', isActivated: true),
            StemButton('Other', isActivated: true),
          ],
        ),
      ),
    );
  }
}

class StemButton extends StatelessWidget {
  final String stemName;
  final bool isActivated;

  const StemButton(this.stemName, {Key? key, this.isActivated = true})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final icon = isActivated ? Icons.headset : Icons.headset_off;

    return SpacedRow(
      spacing: 10,
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: ColorPalette.onSurface),
        SizedBox(
          width: 125,
          child: Button(
            stemName,
            color: ColorPalette.inverseSurface,
            textColor: ColorPalette.inversePrimary,
            textSize: 16,
            radius: 12,
            padding:
                const EdgeInsets.only(left: 15, top: 5, right: 15, bottom: 5),
          ),
        ),
      ],
    );
  }
}