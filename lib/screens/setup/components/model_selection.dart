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
          models: const {
            'UMXHQ (default)':
                'Model trained on the MUSDB18-HQ dataset (200 MB)',
            'UMXL': 'Model trained on extra data (500 MB)',
          },
          infosUrl: 'https://sigsep.github.io/open-unmix/',
          imagePath: getAssetPath('open_unmix', AssetType.image),
        ),
      ],
    );
  }
}
