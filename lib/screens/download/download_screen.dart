import 'package:auto_size_text/auto_size_text.dart';
import 'package:demixr_app/components/cancel_button.dart';
import 'package:demixr_app/components/extended_widgets.dart';
import 'package:demixr_app/constants.dart';
import 'package:demixr_app/providers/model_provider.dart';
import 'package:flutter/material.dart';
import 'package:get/route_manager.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:provider/provider.dart';

class DownloadScreen extends StatelessWidget {
  const DownloadScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: SpacedColumn(
                spacing: 50,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Consumer<ModelProvider>(
                    builder: (context, modelProvider, child) {
                      return CircularPercentIndicator(
                        radius: 130,
                        lineWidth: 15,
                        percent: modelProvider.progress,
                        backgroundColor: ColorPalette.surfaceVariant,
                        progressColor: ColorPalette.primary,
                        circularStrokeCap: CircularStrokeCap.round,
                        center: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${modelProvider.currentDownloaded}',
                              style: const TextStyle(
                                fontSize: 48,
                                fontWeight: FontWeight.w600,
                                color: ColorPalette.primary,
                              ),
                            ),
                            const Text(
                              ' MB',
                              style: TextStyle(
                                fontSize: 18,
                                color: ColorPalette.primary,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  Consumer<ModelProvider>(
                    builder: (context, modelProvider, child) => AutoSizeText(
                      modelProvider.warmingUp
                          ? 'Optimizing the model for your device'
                          : 'The model is being downloaded',
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      style: const TextStyle(
                        fontSize: 20,
                        color: ColorPalette.onSurfaceVariant,
                      ),
                    ),
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
            ),
          ),
        ),
      ),
    );
  }
}
