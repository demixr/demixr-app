import 'package:demixr_app/components/extended_widgets.dart';
import 'package:demixr_app/models/model.dart';
import 'package:flutter/material.dart';

import '../../../constants.dart';

class ModelCard extends StatelessWidget {
  final Model model;
  final String imagePath;

  const ModelCard({
    required this.model,
    required this.imagePath,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      color: ColorPalette.surfaceVariant,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: SpacedRow(
          spacing: 10,
          children: [
            CircleAvatar(
              backgroundColor: ColorPalette.surface,
              radius: 30,
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
          ],
        ),
      ),
    );
  }
}
