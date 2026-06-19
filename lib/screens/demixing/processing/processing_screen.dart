import 'package:auto_size_text/auto_size_text.dart';
import 'package:demixr_app/components/extended_widgets.dart';
import 'package:demixr_app/constants.dart';
import 'package:demixr_app/components/cancel_button.dart';
import 'package:demixr_app/utils.dart';
import 'package:flutter/material.dart';
import 'package:get/route_manager.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';

class ProcessingScreen extends StatelessWidget {
  const ProcessingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final demixingProvider = Get.arguments;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxHeight: 220,
                    maxWidth: 320,
                  ),
                  child: Image.asset(
                    getAssetPath('demixing', AssetType.animation),
                  ),
                ),
                const SizedBox(height: 20),
                SpacedColumn(
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
                const SizedBox(height: 20),
                StreamBuilder<double>(
                  stream: demixingProvider.progressStream,
                  builder: (context, snapshot) {
                    final progress = snapshot.hasData ? snapshot.data! : 0.0;
                    return LinearPercentIndicator(
                      percent: progress.clamp(0.0, 1.0),
                      lineHeight: 20,
                      backgroundColor: ColorPalette.surfaceVariant,
                      progressColor: ColorPalette.primary,
                      barRadius: const Radius.circular(10),
                      animation: true,
                      animationDuration: 1000,
                      animateFromLastPercent: true,
                    );
                  },
                ),
                const SizedBox(height: 20),
                CancelButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      barrierDismissible: true,
                      builder: (context) {
                        return AlertDialog(
                          title: const Text('Cancel'),
                          elevation: 24,
                          content: const Text(
                            'Do you really want to cancel the demixing?',
                          ),
                          backgroundColor: ColorPalette.surfaceVariant,
                          actions: [
                            TextButton(
                              onPressed: Get.back,
                              child: const Text(
                                'No',
                                style: TextStyle(color: ColorPalette.primary),
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                demixingProvider.cancelDemixing();
                                Get.back();
                              },
                              child: const Text(
                                'Yes, cancel',
                                style: TextStyle(color: ColorPalette.primary),
                              ),
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
