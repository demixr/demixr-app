import 'package:demixr_app/components/buttons.dart';
import 'package:demixr_app/components/extended_widgets.dart';
import 'package:demixr_app/models/model.dart';
import 'package:demixr_app/providers/preferences_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../constants.dart';
import '../../../utils.dart';

class ModelSelection extends StatelessWidget {
  const ModelSelection({Key? key}) : super(key: key);

  Future<Widget> buildSelectButton(BuildContext context, Model model) async {
    final preferences = context.read<PreferencesProvider>();
    if (preferences.isModelSelected(model)) {
      return const IconButton(
        onPressed: null,
        icon: Icon(
          Icons.check,
          color: Colors.greenAccent,
        ),
      );
    } else if (await preferences.isModelAvailable(model)) {
      return Button(
        'Use'.toUpperCase(),
        color: Colors.transparent,
        textColor: ColorPalette.primary,
        onPressed: () {},
      );
    } else {
      return Button(
        'Download'.toUpperCase(),
        color: Colors.transparent,
        textColor: ColorPalette.primary,
        onPressed: () {},
      );
    }
  }

  Widget buildModelTile(BuildContext context, Model model, String imagePath) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: SpacedRow(
        spacing: 10,
        children: [
          CircleAvatar(
            backgroundColor: ColorPalette.surface,
            radius: 25,
            backgroundImage: Image.asset(
              imagePath,
            ).image,
          ),
          Expanded(
            child: SpacedColumn(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 5,
              children: [
                Text(
                  model.name.toUpperCase() +
                      (model.isDefault ? ' (default)' : ''),
                  style: const TextStyle(fontSize: 16),
                ),
                Text(
                  model.description,
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
          FutureBuilder<Widget>(
            future: buildSelectButton(context, model),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                return snapshot.data!;
              } else {
                return const CircularProgressIndicator(
                    color: ColorPalette.primary);
              }
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget title = const Text(
      'Model selection',
      style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
    );

    List<Widget> children = [
      for (var model in Models.all)
        buildModelTile(
          context,
          model,
          getAssetPath('open_unmix', AssetType.image),
        )
    ];

    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 20),
      child: SpacedColumn(
        spacing: 10,
        mainAxisAlignment: MainAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(10),
            child: title,
          ),
          ...children
        ],
      ),
    );
  }
}
