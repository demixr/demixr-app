import 'package:demixr_app/components/navbar.dart';
import 'package:demixr_app/components/page_title.dart';
import 'package:demixr_app/constants.dart';
import 'package:demixr_app/providers/song_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'model_selection.dart';
import 'song_selection.dart';
import 'unmix_button.dart';

class SelectionScreen extends StatelessWidget {
  const SelectionScreen({super.key});

  Widget buildNavBar(BuildContext context) => NavBar(
    extra: [
      IconButton(
        tooltip: 'Separation model',
        icon: const Icon(Icons.tune_rounded, color: ColorPalette.onSurface),
        onPressed: () {
          showModalBottomSheet(
            backgroundColor: ColorPalette.surface,
            showDragHandle: true,
            isScrollControlled: true,
            constraints: const BoxConstraints(maxWidth: 720),
            context: context,
            builder: (context) {
              return const ModelSelection();
            },
          );
        },
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ChangeNotifierProvider(
        create: (context) => SongProvider(),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: buildNavBar(context),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 760),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        PageTitle('New separation'),
                        SizedBox(height: 28),
                        SongSelection(),
                        SizedBox(height: 24),
                        SizedBox(width: double.infinity, child: UnmixButton()),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
