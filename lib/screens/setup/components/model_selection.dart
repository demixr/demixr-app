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
          title: 'Demucs v4',
          models: const [Models.htdemucs, Models.htdemucsFt, Models.htdemucs6s],
          infosUrl: Models.demucsExecutorchRepoUrl,
          imagePath: getAssetPath('open_unmix', AssetType.image),
        ),
      ],
    );
  }
}
