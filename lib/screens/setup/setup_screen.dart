import 'package:demixr_app/providers/model_provider.dart';
import 'package:demixr_app/providers/preferences_provider.dart';
import 'package:demixr_app/screens/setup/components/instructions.dart';
import 'package:demixr_app/screens/setup/components/model_selection.dart';
import 'package:demixr_app/screens/setup/components/setup_title.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SetupScreen extends StatelessWidget {
  const SetupScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final preferences = context.read<PreferencesProvider>();
    return ChangeNotifierProvider<ModelProvider>(
      create: (context) => ModelProvider(
          repository: preferences.repository, preferences: preferences),
      child: Scaffold(
        body: Container(
          margin:
              const EdgeInsets.only(left: 20, top: 70, right: 20, bottom: 30),
          height: double.maxFinite,
          width: double.maxFinite,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: const [
              SetupTitle(),
              Instructions(),
              ModelSelection(),
            ],
          ),
        ),
      ),
    );
  }
}
