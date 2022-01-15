import 'package:demixr_app/components/extended_widgets.dart';
import 'package:demixr_app/constants.dart';
import 'package:demixr_app/components/cancel_button.dart';
import 'package:demixr_app/providers/demixing_provider.dart';
import 'package:demixr_app/utils.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class LoadingScreen extends StatelessWidget {
  const LoadingScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final demixingProvider = context.read<DemixingProvider>();

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
          SpacedColumn(
            spacing: 5,
            children: const [
              Text(
                'Demixing in progress',
                style: TextStyle(
                  color: ColorPalette.onSurfaceVariant,
                  fontSize: 20,
                ),
              ),
              Text(
                'This may take a few minutes',
                style: TextStyle(
                  color: ColorPalette.onSurfaceVariant,
                  fontSize: 20,
                ),
              ),
            ],
          ),
          CancelButton(onPressed: () => demixingProvider.cancelDemixing()),
        ],
      ),
    );
  }
}
