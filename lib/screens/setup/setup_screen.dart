import 'package:demixr_app/providers/preferences_provider.dart';
import 'package:demixr_app/screens/setup/components/download_progress.dart';
import 'package:demixr_app/screens/setup/components/instructions.dart';
import 'package:demixr_app/screens/setup/components/model_selection.dart';
import 'package:demixr_app/screens/setup/components/setup_title.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SetupScreen extends StatelessWidget {
  const SetupScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        margin: const EdgeInsets.only(left: 20, top: 70, right: 20, bottom: 30),
        height: double.maxFinite,
        width: double.maxFinite,
        child: Expanded(
          child: Consumer<PreferencesProvider>(
              builder: (context, preferences, child) {
            final children = preferences.downloadInProgress
                ? const [DownloadProgress()]
                : const [
                    SetupTitle(),
                    Instructions(),
                    ModelSelection(),
                  ];

            return Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: children,
            );
          }),
        ),
      ),
    );
  }
}
