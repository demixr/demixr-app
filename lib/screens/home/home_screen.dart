import 'package:demixr_app/components/buttons.dart';
import 'package:demixr_app/providers/preferences_provider.dart';
import 'package:demixr_app/screens/setup/setup_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

import '../../constants.dart';
import 'components/home_title.dart';
import 'components/library.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Widget buildHomeScreen() {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.only(
          top: 20,
          left: 20,
          right: 20,
          bottom: 20,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const HomeTitle(),
            const SizedBox(height: 60),
            // Library returns an Expanded, so it fills the remaining height and
            // its song list scrolls internally; the button stays pinned below.
            const Library(),
            const SizedBox(height: 20),
            Button(
              'Unmix a new song',
              icon: const Icon(Icons.add, color: ColorPalette.onPrimary),
              textSize: 18,
              onPressed: () => Get.toNamed('/demixing'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PreferencesProvider>(
      builder: (context, preferences, child) {
        return preferences.hasModel ? buildHomeScreen() : const SetupScreen();
      },
    );
  }
}
