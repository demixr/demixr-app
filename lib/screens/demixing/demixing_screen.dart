import 'package:demixr_app/providers/demixing_provider.dart';
import 'package:demixr_app/providers/preferences_provider.dart';
import 'package:demixr_app/screens/demixing/components/selection_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class DemixingScreen extends StatelessWidget {
  const DemixingScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ChangeNotifierProvider(
        create: (context) =>
            DemixingProvider(context.read<PreferencesProvider>()),
        child: Consumer<DemixingProvider>(
          builder: (context, demixingProvider, child) {
            return const SelectionScreen();
          },
        ),
      ),
    );
  }
}
