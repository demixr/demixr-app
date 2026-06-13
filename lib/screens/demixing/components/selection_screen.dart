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
  const SelectionScreen({Key? key}) : super(key: key);

  Widget buildNavBar(BuildContext context) => NavBar(extra: [
        IconButton(
          icon: const Icon(
            Icons.more_vert,
            color: ColorPalette.onSurface,
          ),
          onPressed: () {
            showModalBottomSheet(
              backgroundColor: ColorPalette.surface,
              context: context,
              builder: (context) {
                return const ModelSelection();
              },
            );
          },
        )
      ]);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          buildNavBar(context),
          const SizedBox(height: 20),
          Expanded(
            child: ChangeNotifierProvider(
              create: (context) => SongProvider(),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: const [
                    PageTitle('Demixing'),
                    SongSelection(),
                    SizedBox(height: 20),
                    FractionallySizedBox(
                      widthFactor: 0.7,
                      child: UnmixButton(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
