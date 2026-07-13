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
            final isCompact = constraints.maxHeight < 700;
            final horizontalPadding = isDesktop ? 48.0 : 20.0;
            final verticalPadding = isCompact
                ? 20.0
                : (isDesktop ? 40.0 : 28.0);
            return SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: verticalPadding,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - (verticalPadding * 2),
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1200),
                    child: isDesktop
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SetupTitle(compact: isCompact),
                                    SizedBox(height: isCompact ? 20 : 32),
                                    Instructions(compact: isCompact),
                                  ],
                                ),
                              ),
                              SizedBox(width: isCompact ? 40 : 64),
                              Expanded(
                                child: ModelSelection(compact: isCompact),
                              ),
                            ],
                          )
                        : Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              SetupTitle(compact: isCompact),
                              SizedBox(height: isCompact ? 20 : 30),
                              Instructions(compact: isCompact),
                              SizedBox(height: isCompact ? 20 : 28),
                              ModelSelection(compact: isCompact),
                            ],
                          ),
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
