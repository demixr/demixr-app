import 'package:demixr_app/components/buttons.dart';
import 'package:flutter/material.dart';

import '../../constants.dart';
import 'components/home_title.dart';
import 'components/library.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        margin:
            const EdgeInsets.only(top: 125, left: 20, right: 20, bottom: 20),
        height: double.maxFinite,
        width: double.maxFinite,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const HomeTitle(),
            const SizedBox(height: 60),
            Expanded(
              child: Column(
                children: [
                  const Expanded(
                    child: Library(),
                  ),
                  Button(
                    'Unmix a new song',
                    icon: const Icon(
                      Icons.add,
                      color: ColorPalette.onPrimary,
                    ),
                    textSize: 18,
                    onPressed: () => Navigator.pushNamed(context, 'demixing'),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
