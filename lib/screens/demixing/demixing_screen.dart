import 'package:demixr_app/components/buttons.dart';
import 'package:demixr_app/components/navbar.dart';
import 'package:demixr_app/components/page_title.dart';
import 'package:demixr_app/providers/song_provider.dart';
import 'package:demixr_app/screens/demixing/components/unmix_button.dart';
import 'package:demixr_app/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';

import '../../constants.dart';
import 'components/song_selection.dart';

class DemixingScreen extends StatelessWidget {
  const DemixingScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
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
                    UnmixButton(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
