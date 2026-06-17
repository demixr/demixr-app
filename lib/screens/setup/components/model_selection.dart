import 'dart:io' show Platform;

import 'package:demixr_app/constants.dart';
import 'package:demixr_app/screens/setup/components/model_group.dart';
import 'package:demixr_app/utils.dart';
import 'package:flutter/material.dart';

class ModelSelection extends StatelessWidget {
  const ModelSelection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        ModelGroup(
          title: 'Demucs',
          models: const [Models.htdemucs],
          imagePath: getAssetPath('open_unmix', AssetType.image),
        ),
        // The OpenUnmix engine is native Android-only.
        if (Platform.isAndroid)
          ModelGroup(
            title: 'Open-Unmix',
            models: const [Models.umxhq, Models.umxl],
            infosUrl: Models.openUnmixInfosUrl,
            imagePath: getAssetPath('open_unmix', AssetType.image),
          ),
      ],
    );
  }
}
