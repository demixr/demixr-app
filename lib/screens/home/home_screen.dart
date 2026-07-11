import 'package:demixr_app/components/buttons.dart';
import 'package:demixr_app/providers/preferences_provider.dart';
import 'package:demixr_app/screens/setup/setup_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

import '../../constants.dart';
import 'components/home_title.dart';
import 'components/library.dart';
import 'components/now_playing_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Widget buildHomeScreen(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isDesktop = constraints.maxWidth >= LayoutBreakpoints.desktop;
            final isCompactDesktop =
                constraints.maxWidth < LayoutBreakpoints.compactDesktop;
            final horizontalPadding = isDesktop
                ? (isCompactDesktop ? 32.0 : 48.0)
                : 20.0;
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
                              width: isCompactDesktop ? 280 : 310,
                              child: LayoutBuilder(
                                builder: (context, rail) {
                                  final isShort = rail.maxHeight < 520;

                                  if (isShort) {
                                    final designHeight = rail.maxHeight.clamp(
                                      220.0,
                                      520.0,
                                    );
                                    return FittedBox(
                                      fit: BoxFit.scaleDown,
                                      alignment: Alignment.topCenter,
                                      child: SizedBox(
                                        width: 310,
                                        height: designHeight,
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.stretch,
                                          children: [
                                            Text(
                                              'Demixr',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .headlineMedium
                                                  ?.copyWith(fontSize: 38),
                                            ),
                                            const SizedBox(height: 10),
                                            const Expanded(
                                              child: FittedBox(
                                                fit: BoxFit.scaleDown,
                                                child: SizedBox(
                                                  width: 310,
                                                  child: NowPlayingCard(
                                                    compact: true,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(height: 10),
                                            SizedBox(
                                              width: double.infinity,
                                              child: action,
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  }

                                  return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      const HomeTitle(),
                                      const SizedBox(height: 28),
                                      const Expanded(child: NowPlayingCard()),
                                      const SizedBox(height: 24),
                                      SizedBox(
                                        width: double.infinity,
                                        child: action,
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ),
                            SizedBox(width: isCompactDesktop ? 32 : 64),
                            const Expanded(child: Library()),
                          ],
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const HomeTitle(),
                            const SizedBox(height: 20),
                            const NowPlayingCard(compact: true),
                            const SizedBox(height: 24),
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
