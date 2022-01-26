import 'package:demixr_app/components/buttons.dart';
import 'package:demixr_app/providers/library_provider.dart';
import 'package:flutter/material.dart';
import 'package:get/route_manager.dart';
import 'package:provider/provider.dart';

import '../../../constants.dart';

class InfosDialog extends StatelessWidget {
  const InfosDialog({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final library = context.read<LibraryProvider>();

    String songTitle =
        library.currentSong.fold((l) => 'unknown', (r) => r.title);
    String modelName =
        library.currentSong.fold((l) => 'unknown', (r) => r.modelName);

    return AlertDialog(
      title: Text(songTitle),
      elevation: 24,
      content: RichText(
        text: TextSpan(
          style: const TextStyle(color: ColorPalette.onSurfaceVariant),
          children: [
            const TextSpan(text: 'This song was unmixed with '),
            TextSpan(
              text: modelName,
              style: const TextStyle(
                color: Colors.redAccent,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
      backgroundColor: ColorPalette.surfaceVariant,
      actions: [
        Button(
          'Ok'.toUpperCase(),
          color: Colors.transparent,
          textColor: ColorPalette.primary,
          onPressed: Get.back,
        )
      ],
    );
  }
}
