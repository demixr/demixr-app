import 'package:demixr_app/screens/setup/components/instructions.dart';
import 'package:demixr_app/screens/setup/components/model_selection.dart';
import 'package:demixr_app/screens/setup/components/setup_title.dart';
import 'package:flutter/material.dart';

class SetupScreen extends StatelessWidget {
  const SetupScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        margin: const EdgeInsets.only(left: 20, top: 50, right: 20, bottom: 30),
        height: double.maxFinite,
        width: double.maxFinite,
        child: Expanded(
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
