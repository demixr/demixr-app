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
  const HomeScreen({Key? key}) : super(key: key);

  Widget buildHomeScreen() {
    return Scaffold(
      body: Container(
        margin:
            const EdgeInsets.only(top: 125, left: 20, right: 20, bottom: 20),
        height: double.maxFinite,
        width: double.maxFinite,
        child: Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const HomeTitle(),
              const SizedBox(height: 60),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Library(),
                    Button(
                      'Unmix a new song',
                      icon: const Icon(
                        Icons.add,
                        color: ColorPalette.onPrimary,
                      ),
                      textSize: 18,
                      onPressed: () => Get.toNamed('/demixing'),
                    )
                  ],
                ),
              ),
            ],
          ),
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
