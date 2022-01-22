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
        margin:
            const EdgeInsets.only(left: 20, top: 125, right: 20, bottom: 20),
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
            StreamBuilder<double>(
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
            CancelButton(onPressed: () => demixingProvider.cancelDemixing()),
          ],
        ),
      ),
    );
  }
}
