import 'package:demixr_app/components/buttons.dart';
import 'package:demixr_app/components/extended_widgets.dart';
import 'package:demixr_app/helpers/separation/executorch_demixing_engine.dart';
import 'package:demixr_app/models/model.dart';
import 'package:demixr_app/providers/model_provider.dart';
import 'package:demixr_app/providers/preferences_provider.dart';
import 'package:flutter/material.dart';
import 'package:get/route_manager.dart';
import 'package:provider/provider.dart';

import '../../../constants.dart';
import '../../../utils.dart';

class ModelSelection extends StatelessWidget {
  const ModelSelection({super.key});

  /// Selects [model], and for an already-downloaded GPU model kicks off the
  /// CoreML/Vulkan warm-up (fire-and-forget) so switching to it doesn't stall
  /// the first demix on the one-time compile.
  void _useModel(PreferencesProvider preferences, Model model) {
    preferences.setModel(model);
    if (model.engine == DemixingEngine.executorch) {
      final path = preferences.repository.getModelPath(model.name);
      if (path != null) ExecuTorchDemixingEngine.warmUp(path);
    }
  }

  Future<Widget> buildSelectButton(BuildContext context, Model model) async {
    final preferences = context.read<PreferencesProvider>();
    final modelProvider = context.read<ModelProvider>();

    if (await preferences.isModelSelected(model)) {
      return const Chip(
        avatar: Icon(
          Icons.check_rounded,
          size: 17,
          color: ColorPalette.tertiary,
        ),
        label: Text('Active'),
        backgroundColor: ColorPalette.surfaceContainerHigh,
        side: BorderSide(color: ColorPalette.outline),
      );
    } else if (await preferences.isModelAvailable(model)) {
      return Button(
        'Use',
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        onPressed: () => _useModel(preferences, model),
      );
    } else {
      return Button(
        'Download',
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        onPressed: () => modelProvider.downloadModel(model, onDone: Get.back),
      );
    }
  }

  Widget buildModelTile(BuildContext context, Model model, String imagePath) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: ColorPalette.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ColorPalette.outline),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: SpacedRow(
          spacing: 10,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            CircleAvatar(
              backgroundColor: ColorPalette.surfaceContainerHigh,
              radius: 25,
              backgroundImage: Image.asset(imagePath).image,
            ),
            Expanded(
              flex: 7,
              child: SpacedColumn(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 5,
                children: [
                  Text(
                    model.name.toUpperCase() +
                        (model == Models.recommended ? ' (recommended)' : ''),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    model.description,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      color: ColorPalette.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Consumer<PreferencesProvider>(
              builder: (context, preferences, child) {
                return FutureBuilder<Widget>(
                  future: buildSelectButton(context, model),
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      return snapshot.data!;
                    } else {
                      return const CircularProgressIndicator(
                        color: ColorPalette.primary,
                      );
                    }
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget title = const Text(
      'Separation model',
      style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
    );

    List<Widget> children = [
      for (var model in Models.supported)
        buildModelTile(context, model, getAssetPath('demucs', AssetType.image)),
    ];

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
        child: SpacedColumn(
          spacing: 12,
          mainAxisAlignment: MainAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            title,
            const Text(
              'Choose the engine used for new separations.',
              style: TextStyle(color: ColorPalette.onSurfaceVariant),
            ),
            const SizedBox(height: 4),
            ...children,
          ],
        ),
      ),
    );
  }
}
