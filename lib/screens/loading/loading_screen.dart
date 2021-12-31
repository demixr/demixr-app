import 'package:demixr_app/components/extended_widgets.dart';
import 'package:demixr_app/constants.dart';
import 'package:demixr_app/screens/loading/components/cancel_button.dart';
import 'package:demixr_app/utils.dart';
import 'package:flutter/material.dart';

class LoadingScreen extends StatelessWidget {
  const LoadingScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.maxFinite,
      height: double.maxFinite,
      margin: const EdgeInsets.only(left: 20, top: 125, right: 20, bottom: 20),
      alignment: Alignment.center,
      child: SpacedColumn(
        spacing: 50,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Image.asset(
              getAssetPath('demixing', AssetType.animation),
            ),
          ),
          const Text(
            'Demixing in progress',
            style: TextStyle(
              color: ColorPalette.onSurfaceVariant,
              fontSize: 20,
            ),
          ),
          const CancelButton(),
        ],
      ),
    );
  }
}
