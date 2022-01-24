import 'package:auto_size_text/auto_size_text.dart';
import 'package:demixr_app/components/cancel_button.dart';
import 'package:demixr_app/components/extended_widgets.dart';
import 'package:demixr_app/constants.dart';
import 'package:demixr_app/providers/model_provider.dart';
import 'package:flutter/material.dart';
import 'package:get/route_manager.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:provider/provider.dart';

class DownloadProgress extends StatelessWidget {
  const DownloadProgress({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: SpacedColumn(
        spacing: 50,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Consumer<ModelProvider>(
              builder: (context, modelProvider, child) {
                // var progressPercents = (preferences.progress * 100).toInt();
                return CircularPercentIndicator(
                  radius: 250,
                  lineWidth: 15,
                  percent: modelProvider.progress,
                  backgroundColor: ColorPalette.surfaceVariant,
                  progressColor: ColorPalette.primary,
                  circularStrokeCap: CircularStrokeCap.round,
                  center: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${modelProvider.currentDownloaded}',
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
                );
              },
            ),
          ),
          const AutoSizeText(
            'The model is being downloaded',
            textAlign: TextAlign.center,
            maxLines: 2,
            style:
                TextStyle(fontSize: 24, color: ColorPalette.onSurfaceVariant),
          ),
          CancelButton(
            onPressed: () {
              context.read<ModelProvider>().cancelDownload();
              Get.snackbar(
                'Model',
                'Download canceled',
                backgroundColor: ColorPalette.primary,
                colorText: ColorPalette.onPrimary,
              );
            },
          ),
        ],
      ),
    );
  }
}
