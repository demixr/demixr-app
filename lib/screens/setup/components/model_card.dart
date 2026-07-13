import 'package:demixr_app/components/extended_widgets.dart';
import 'package:demixr_app/models/model.dart';
import 'package:flutter/material.dart';

import '../../../constants.dart';

class ModelCard extends StatelessWidget {
  final Model model;
  final String imagePath;
  final bool compact;

  const ModelCard({
    required this.model,
    required this.imagePath,
    this.compact = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: ColorPalette.surfaceContainer,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: ColorPalette.outline),
      ),
      child: Padding(
        padding: EdgeInsets.all(compact ? 12 : 16),
        child: SpacedRow(
          spacing: 10,
          children: [
            CircleAvatar(
              backgroundColor: ColorPalette.surfaceContainerHigh,
              radius: compact ? 24 : 30,
              backgroundImage: Image.asset(imagePath).image,
            ),
            Expanded(
              child: SpacedColumn(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 5,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          model.name.toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      if (model == Models.recommended) ...[
                        const SizedBox(width: 6),
                        const Tooltip(
                          message: 'Recommended',
                          child: Icon(
                            Icons.auto_awesome_rounded,
                            size: 16,
                            color: ColorPalette.tertiary,
                          ),
                        ),
                      ],
                    ],
                  ),
                  Text(
                    model.description,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.35,
                      color: ColorPalette.onSurfaceVariant,
                    ),
                    maxLines: compact ? 2 : 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.arrow_downward_rounded,
              color: ColorPalette.primary,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}
