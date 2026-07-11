import 'package:demixr_app/constants.dart';
import 'package:flutter/material.dart';

class Instructions extends StatelessWidget {
  const Instructions({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Choose your separation engine',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: ColorPalette.onSurface,
          ),
        ),
        SizedBox(height: 8),
        Text(
          'The GPU model is fastest on supported devices. You can change this choice later.',
          style: TextStyle(
            fontSize: 16,
            height: 1.45,
            color: ColorPalette.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
