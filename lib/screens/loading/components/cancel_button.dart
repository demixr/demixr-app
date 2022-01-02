import 'package:demixr_app/components/buttons.dart';
import 'package:demixr_app/constants.dart';
import 'package:demixr_app/providers/demixing_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class CancelButton extends StatelessWidget {
  const CancelButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var demixingProvider = context.read<DemixingProvider>();

    return Button(
      'Cancel',
      icon: const Icon(
        Icons.cancel,
        color: ColorPalette.onError,
      ),
      color: ColorPalette.errorContainer,
      textColor: ColorPalette.onError,
      textSize: 18,
      onPressed: () {
        demixingProvider.cancelDemixing();
      },
    );
  }
}
