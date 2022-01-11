import 'package:demixr_app/components/extended_widgets.dart';
import 'package:flutter/material.dart';

import '../../../constants.dart';

class ModelCard extends StatelessWidget {
  final String name;
  final String description;
  final String imagePath;

  const ModelCard({
    required this.name,
    required this.description,
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
              backgroundColor: ColorPalette.onSurfaceVariant,
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
                    name,
                    style: const TextStyle(fontSize: 16),
                  ),
                  Text(
                    description,
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
