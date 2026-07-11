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

  Widget buildHomeScreen(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isDesktop = constraints.maxWidth >= 820;
            final horizontalPadding = isDesktop ? 48.0 : 20.0;
            final action = Button(
              'Unmix a new song',
              icon: const Icon(
                Icons.add_rounded,
                color: ColorPalette.onPrimary,
              ),
              textSize: 16,
              onPressed: () => Get.toNamed('/demixing'),
            );

            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1280),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    isDesktop ? 44 : 24,
                    horizontalPadding,
                    24,
                  ),
                  child: isDesktop
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            SizedBox(
                              width: 310,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const HomeTitle(),
                                  const Spacer(),
                                  SizedBox(
                                    width: double.infinity,
                                    child: action,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 64),
                            const Expanded(child: Library()),
                          ],
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const HomeTitle(),
                            const SizedBox(height: 40),
                            const Expanded(child: Library()),
                            const SizedBox(height: 16),
                            SizedBox(width: double.infinity, child: action),
                          ],
                        ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PreferencesProvider>(
      builder: (context, preferences, child) {
        return preferences.hasModel
            ? buildHomeScreen(context)
            : const SetupScreen();
      },
    );
  }
}
