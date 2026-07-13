import 'package:demixr_app/constants.dart';
import 'package:demixr_app/screens/setup/components/model_group.dart';
import 'package:demixr_app/utils.dart';
import 'package:flutter/material.dart';

class ModelSelection extends StatelessWidget {
  final bool compact;

  const ModelSelection({this.compact = false, super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        ModelGroup(
          title: 'Demucs',
          models: Models.all,
          imagePath: getAssetPath('demucs', AssetType.image),
          compact: compact,
        ),
      ],
    );
  }
}
