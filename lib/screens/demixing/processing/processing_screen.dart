import 'package:auto_size_text/auto_size_text.dart';
import 'package:demixr_app/components/buttons.dart';
import 'package:demixr_app/components/extended_widgets.dart';
import 'package:demixr_app/constants.dart';
import 'package:demixr_app/components/cancel_button.dart';
import 'package:demixr_app/utils.dart';
import 'package:flutter/material.dart';
import 'package:get/route_manager.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';

class ProcessingScreen extends StatelessWidget {
  const ProcessingScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final demixingProvider = Get.arguments;

    return Scaffold(
      body: Container(
        width: double.maxFinite,
        height: double.maxFinite,
        margin: const EdgeInsets.all(20),
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Spacer(flex: 2),
            Expanded(
              flex: 6,
              child: Image.asset(
                getAssetPath('demixing', AssetType.animation),
              ),
            ),
            Expanded(
              flex: 1,
              child: SpacedColumn(
                spacing: 5,
                children: const [
                  AutoSizeText(
                    'Demixing in progress',
                    style: TextStyle(
                      color: ColorPalette.onSurfaceVariant,
                      fontSize: 20,
                    ),
                  ),
                  AutoSizeText(
                    'This may take a few minutes',
                    style: TextStyle(
                      color: ColorPalette.onSurfaceVariant,
                      fontSize: 20,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 1,
              child: StreamBuilder<double>(
                stream: demixingProvider.progressStream,
                builder: (context, snapshot) {
                  double progress = 0;
                  if (snapshot.hasData) progress = snapshot.data!;
                  return LinearPercentIndicator(
                    percent: progress,
                    backgroundColor: ColorPalette.surfaceVariant,
                    progressColor: ColorPalette.primary,
                    linearStrokeCap: LinearStrokeCap.round,
                    animation: true,
                    animationDuration: 1000,
                    animateFromLastPercent: true,
                  );
                },
              ),
            ),
            CancelButton(onPressed: () {
              showDialog(
                  context: context,
                  barrierDismissible: true,
                  builder: (context) {
                    return AlertDialog(
                      title: const Text('Cancel'),
                      elevation: 24,
                      content: const Text(
                          'Do you really want to cancel the demixing?'),
                      backgroundColor: ColorPalette.surfaceVariant,
                      actions: [
                        TextButton(
                          child: const Text(
                            'No',
                            style: TextStyle(color: ColorPalette.primary),
                          ),
                          onPressed: Get.back,
                        ),
                        TextButton(
                          child: const Text(
                            'Yes, cancel',
                            style: TextStyle(color: ColorPalette.primary),
                          ),
                          onPressed: () {
                            demixingProvider.cancelDemixing();
                            Get.back();
                          },
                        ),
                      ],
                    );
                  });
            }),
          ],
        ),
      ),
    );
  }
}
