import 'package:demixr_app/screens/setup/components/instructions.dart';
import 'package:demixr_app/screens/setup/components/model_selection.dart';
import 'package:demixr_app/screens/setup/components/setup_title.dart';
import 'package:demixr_app/constants.dart';
import 'package:flutter/material.dart';

class SetupScreen extends StatelessWidget {
  const SetupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isDesktop = constraints.maxWidth >= LayoutBreakpoints.desktop;
            return SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: isDesktop ? 48 : 20,
                vertical: isDesktop ? 48 : 28,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1120),
                  child: isDesktop
                      ? const Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SetupTitle(),
                                  SizedBox(height: 32),
                                  Instructions(),
                                ],
                              ),
                            ),
                            SizedBox(width: 64),
                            Expanded(child: ModelSelection()),
                          ],
                        )
                      : const Column(
                          children: [
                            SetupTitle(),
                            SizedBox(height: 32),
                            Instructions(),
                            SizedBox(height: 32),
                            ModelSelection(),
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
}
