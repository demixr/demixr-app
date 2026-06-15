import 'package:auto_size_text/auto_size_text.dart';
import 'package:demixr_app/components/extended_widgets.dart';
import 'package:demixr_app/constants.dart';
import 'package:demixr_app/components/cancel_button.dart';
import 'package:demixr_app/utils.dart';
import 'package:flutter/material.dart';
import 'package:get/route_manager.dart';

class ProcessingScreen extends StatelessWidget {
  const ProcessingScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final demixingProvider = Get.arguments;

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Spacer(flex: 2),
            Image.asset(
              getAssetPath('demixing', AssetType.animation),
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
            // Indeterminate progress bar (0.4.1 doesn't expose progress callbacks)
            LinearProgressIndicator(
              minHeight: 20,
              backgroundColor: ColorPalette.surfaceVariant,
              valueColor: const AlwaysStoppedAnimation<Color>(ColorPalette.primary),
              borderRadius: const BorderRadius.all(Radius.circular(10)),
            ),
            const SizedBox(height: 20),
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
                  });
            }),
          ],
        ),
      ),
    );
  }
}
