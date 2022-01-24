import 'package:demixr_app/components/navbar.dart';
import 'package:demixr_app/components/page_title.dart';
import 'package:demixr_app/providers/song_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'song_selection.dart';
import 'unmix_button.dart';

class SelectionScreen extends StatelessWidget {
  const SelectionScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: double.maxFinite,
      width: double.maxFinite,
      margin: const EdgeInsets.all(10),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          const NavBar(),
          const SizedBox(height: 20),
          Expanded(
            child: ChangeNotifierProvider(
              create: (context) => SongProvider(),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: const [
                  PageTitle('Demixing'),
                  SongSelection(),
                  FractionallySizedBox(
                    child: UnmixButton(),
                    widthFactor: 0.7,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
