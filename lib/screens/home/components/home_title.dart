import 'package:demixr_app/constants.dart';
import 'package:flutter/material.dart';

class HomeTitle extends StatelessWidget {
  const HomeTitle({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: const [
        Text(
          'Demixr',
          style: TextStyle(
            fontSize: 72,
            fontWeight: FontWeight.normal,
            color: ColorPalette.primary,
          ),
        ),
        Text(
          'Music demixing in your pocket',
          style: TextStyle(fontSize: 14),
        )
      ],
    );
  }
}
