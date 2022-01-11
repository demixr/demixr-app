import 'package:demixr_app/constants.dart';
import 'package:demixr_app/providers/preferences_provider.dart';
import 'package:flutter/material.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:provider/provider.dart';

class DownloadProgress extends StatelessWidget {
  const DownloadProgress({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Consumer<PreferencesProvider>(
            builder: (context, preferences, child) {
              // var progressPercents = (preferences.progress * 100).toInt();
              return CircularPercentIndicator(
                radius: 250,
                lineWidth: 15,
                percent: preferences.progress,
                backgroundColor: ColorPalette.surfaceVariant,
                progressColor: ColorPalette.primary,
                circularStrokeCap: CircularStrokeCap.round,
                center: Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${preferences.currentDownloaded}',
                        style: const TextStyle(
                          fontSize: 64,
                          fontWeight: FontWeight.w600,
                          color: ColorPalette.primary,
                        ),
                      ),
                      const Text(
                        ' MB',
                        style: TextStyle(
                            fontSize: 24, color: ColorPalette.primary),
                      )
                    ],
                  ),
                ),
              );
            },
          ),
          const Text(
            'The model is being downloaded',
            textAlign: TextAlign.center,
            style:
                TextStyle(fontSize: 24, color: ColorPalette.onSurfaceVariant),
          )
        ],
      ),
    );
  }
}
