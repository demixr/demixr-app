import 'package:demixr_app/providers/library_provider.dart';
import 'package:flutter/material.dart';
import 'package:get/route_manager.dart';
import 'package:provider/provider.dart';

import '../../../constants.dart';

class InfosDialog extends StatelessWidget {
  const InfosDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final library = context.read<LibraryProvider>();

    String songTitle = library.currentSong.fold(
      (l) => 'unknown',
      (r) => r.title,
    );
    String modelName = library.currentSong.fold(
      (l) => 'unknown',
      (r) => r.modelName,
    );

    return AlertDialog(
      backgroundColor: ColorPalette.surfaceContainer,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: ColorPalette.outline),
      ),
      icon: const Icon(Icons.graphic_eq_rounded, color: ColorPalette.primary),
      title: Text(songTitle),
      elevation: 0,
      content: RichText(
        text: TextSpan(
          style: const TextStyle(color: ColorPalette.onSurfaceVariant),
          children: [
            const TextSpan(text: 'This song was unmixed with '),
            TextSpan(
              text: modelName,
              style: const TextStyle(
                color: ColorPalette.primary,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
      actions: [TextButton(onPressed: Get.back, child: const Text('Done'))],
    );
  }
}
