import 'package:demixr_app/constants.dart';
import 'package:demixr_app/screens/setup/components/model_group.dart';
import 'package:demixr_app/utils.dart';
import 'package:flutter/material.dart';

class ModelSelection extends StatelessWidget {
  const ModelSelection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
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
